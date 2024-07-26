extends Node2D

func _process(delta):
	if (animationProcessing): 
		processAnimation(delta);
	else: 
		processInput();

func getPlayerPos() -> Array:
	var entityRect : Rect2i = $Entities.get_used_rect();
	for x in range(entityRect.size.x):
		for y in range(entityRect.size.y):
			var pos : Vector2i = Vector2i(x, y) + entityRect.position;
			if ($Entities.get_cell_atlas_coords(0, pos).x == 0):
				return [true, pos];
	return [false, Vector2i(-9999, -9999)];
	
func checkIfWall(pos : Vector2i) -> bool:
	var wallRect : Rect2i = $Walls.get_used_rect();
	if (!wallRect.has_point(pos)): return false;
	return $Walls.get_cell_source_id(0, pos) != -1;
	
func checkIfEntity(pos : Vector2i) -> bool:
	var entityRect : Rect2i = $Entities.get_used_rect();
	if (!entityRect.has_point(pos)): return false;
	return $Entities.get_cell_source_id(0, pos) != -1;

var inputMovementLastPrioritizedY : bool = false;
func processInput():
	var movement : Vector2i = Vector2i(
		Input.get_axis("player_movement_left", "player_movement_right"),
		Input.get_axis("player_movement_up", "player_movement_down"),
	);
	if (movement.length_squared() <= 0):
		return;
		
	# Only one movement axis at a time please.
	if (abs(movement.x) == abs(movement.y)): 
		inputMovementLastPrioritizedY = !inputMovementLastPrioritizedY;
		if (inputMovementLastPrioritizedY): movement.y = 0;
		else: movement.x = 0;
		
	var playerPos : Vector2i;
	match (getPlayerPos()):
		[ false, _ ]: 
			printerr("Failed to find player.")
			return;
		[ true, var playerPosUntyped]:
			playerPos = playerPosUntyped;
	
	# Check for wall.
	var targetPos : Vector2i = playerPos + movement;
	if (checkIfWall(targetPos)): return
	
	# Make sure an entity isnt in the way.
	if (checkIfEntity(targetPos)): 
		# Check if entity is blocked.
		var entityTargetPos : Vector2i = targetPos + movement;
		if (checkIfWall(entityTargetPos) || checkIfEntity(entityTargetPos)):
			return;
		
		# TODO: Check if entity is pushable.

		# Set animation data.
		var entitySource : int = $Entities.get_cell_source_id(0, targetPos);
		var entityAtlas : Vector2i = $Entities.get_cell_atlas_coords(0, targetPos);
		$Entities.set_cell(0, targetPos);
		$Animation.set_cell(0, targetPos, entitySource, entityAtlas);
		
	# Get player information.
	var playerSource : int = $Entities.get_cell_source_id(0, playerPos);
	var playerAtlas : Vector2i = $Entities.get_cell_atlas_coords(0, playerPos);
	
	# Animation start.
	$Entities.set_cell(0, playerPos);
	$Animation.set_cell(0, playerPos, playerSource, playerAtlas);
	animationTileTargetOffset = movement
	# Set animation state stuff.
	animationProcessing = true;
	# Reset pos + set target.
	$Animation.global_position = Vector2.ZERO;
	animationProgress = 0;
	animationMoveTarget = movement * $Entities.tile_set.tile_size;

@export var animationTime : float = 0.2;
@export var animationLerp : Curve;
var animationProcessing : bool = false;
var animationProgress : float = 0;
var animationMoveTarget : Vector2 = Vector2.ZERO;
var animationTileTargetOffset : Vector2i = Vector2i.ZERO;
func processAnimation(delta):
	# Update animation progress.
	animationProgress = min(animationProgress + (delta / animationTime), 1.0);
	# Move position.
	$Animation.global_position = $Animation.global_position.lerp(animationMoveTarget, animationLerp.sample(animationProgress));
	
	# If position reached, animation ended.
	if (animationProgress < 1.0): return;
	
	# Animation end.
	animationProcessing = false;
	var animationRect : Rect2i = $Animation.get_used_rect();
	
	# Copy animation tilemap to entities.
	for x in range(animationRect.size.x):
		for y in range(animationRect.size.y):
			var pos : Vector2i = animationRect.position + Vector2i(x, y);
			if ($Animation.get_cell_source_id(0, pos) != -1):
				$Entities.set_cell(
					0, pos + animationTileTargetOffset, 
					$Animation.get_cell_source_id(0, pos), 
					$Animation.get_cell_atlas_coords(0, pos)
				);
	# Clear animation tilemap.
	$Animation.clear();
