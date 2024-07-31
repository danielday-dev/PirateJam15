extends Node2D;
class_name ObjectProcess;

enum EntityTileType {
	EntityTileType_None,
	EntityTileType_Player,
	EntityTileType_Box,
	EntityTileType_Light,
	EntityTileType_LightButton,
	EntityTileType_DoorOpen,
	EntityTileType_DoorClose,
};

func onEntityMove(entityType : EntityTileType, from : Vector2i, to : Vector2i) -> void:
	match (entityType):
		EntityTileType.EntityTileType_Player:
			return;
		
		EntityTileType.EntityTileType_Light:
			$Lighting.moveEmitter(from, to);
			$Lighting.enableEmitter(to);
	
	updateLighting();			

func isEntityTypeSolid(entityType : EntityTileType) -> bool:
	match (entityType):
		EntityTileType.EntityTileType_None, EntityTileType.EntityTileType_Player: return false;
		EntityTileType.EntityTileType_LightButton: return false;
		
		EntityTileType.EntityTileType_DoorOpen: return false;
		EntityTileType.EntityTileType_DoorClose: return true;
	return true;
	
func isEntityTypeShadowable(entityType : EntityTileType) -> bool:
	match (entityType):
		EntityTileType.EntityTileType_None, EntityTileType.EntityTileType_Player: return false;
		EntityTileType.EntityTileType_DoorOpen: return false;
		EntityTileType.EntityTileType_DoorClose: return false;
	return true;
	
func isEntityTypePushable(entityType : EntityTileType) -> bool:
	match (entityType):
		EntityTileType.EntityTileType_DoorOpen, EntityTileType.EntityTileType_DoorClose: return false;
	return true;


func getEntityTypeFromAtlas(atlas : Vector2i) -> EntityTileType:
	match (atlas.x):
		0: return EntityTileType.EntityTileType_Player;
		1: return EntityTileType.EntityTileType_Box;
		2, 3, 4, 5, 6, 7, 8: return EntityTileType.EntityTileType_Light;
		9, 10, 11, 12, 13, 14, 15: return EntityTileType.EntityTileType_DoorClose;
		
	return EntityTileType.EntityTileType_None;
	
		
func getEntityTileType(pos : Vector2i) -> EntityTileType:
	var entityRect : Rect2i = $Entities.get_used_rect();
	if (!entityRect.has_point(pos)): return EntityTileType.EntityTileType_None;
	if ($Entities.get_cell_source_id(0, pos) == -1): return EntityTileType.EntityTileType_None;
	
	return getEntityTypeFromAtlas($Entities.get_cell_atlas_coords(0, pos));
	
	
func getBackgroundEntityTypeFromAtlas(atlas : Vector2i) -> EntityTileType:
	match (atlas.x):
		0, 1, 2, 3, 4, 5, 6: return EntityTileType.EntityTileType_LightButton;
	return EntityTileType.EntityTileType_None;
	
func getBackgroundEntityTileType(pos : Vector2i) -> EntityTileType:
	var backgroundRect : Rect2i = $BackgroundEntities.get_used_rect();
	if (!backgroundRect.has_point(pos)): return EntityTileType.EntityTileType_None;
	if ($BackgroundEntities.get_cell_source_id(0, pos) == -1): return EntityTileType.EntityTileType_None;
	
	return getBackgroundEntityTypeFromAtlas($BackgroundEntities.get_cell_atlas_coords(0, pos));


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
	
class LightButton:
	var position : Vector2i;
	var color : int;
	var lit : bool;
	func _init(_position : Vector2i, _color : int):
		position = _position;
		color = _color;
		lit = false;
		
class Door:
	var position : Vector2i;
	var color : int;
	var open : bool;
	func _init(_position : Vector2i, _color):
		position = _position;
		color = _color;
		open = false;

var lightButtons : Array[LightButton];
var doors : Array[Door];
func registerLighting():
	$Lighting.clearEmitters();
	
	var entityRect : Rect2i = $Entities.get_used_rect();
	for x in range(entityRect.size.x):
		for y in range(entityRect.size.y):
			var pos : Vector2i = Vector2i(x, y) + entityRect.position;
			match (getEntityTileType(pos)):
				EntityTileType.EntityTileType_Light:
					var lightCoord : Vector2i = $Entities.get_cell_atlas_coords(0, pos);
					
					var direction : Lighting.Direction = lightCoord.y;
					var color : int = lightCoord.x - 1;
					
					$Lighting.addEmitter(Lighting.Emitter.new(pos, color, direction));
					
				EntityTileType.EntityTileType_DoorClose:
					var doorCoord : Vector2i = $Entities.get_cell_atlas_coords(0, pos);

					var color : int = doorCoord.x - 8;
					if (doorCoord.y >= 1): color |= Lighting.LightingValue.Shadow;
					
					doors.push_back(Door.new(pos, color));
					
	var backgroundRect : Rect2i = $BackgroundEntities.get_used_rect();
	for x in range(backgroundRect.size.x):
		for y in range(backgroundRect.size.y):
			var pos : Vector2i = Vector2i(x, y) + backgroundRect.position;
			match (getBackgroundEntityTileType(pos)):
				EntityTileType.EntityTileType_LightButton:
					var buttonCoord : Vector2i = $BackgroundEntities.get_cell_atlas_coords(0, pos);
					
					var color : int = buttonCoord.x + 1;
					if (buttonCoord.y >= 2): color |= Lighting.LightingValue.Shadow;
					
					lightButtons.push_back(LightButton.new(pos, color));

func updateLighting():
	$Lighting.updateLighting();
	var postLightingUpdateNeeded : bool = false;
	
	# Process buttons.
	for lightButton : LightButton in lightButtons:
		var lightLit : bool = $Lighting.lightingData.has(lightButton.position) && $Lighting.lightingData[lightButton.position].color == lightButton.color;
		
		if (lightButton.lit == lightLit): continue;
		lightButton.lit = lightLit;
		
		$BackgroundEntities.set_cell(
			0, lightButton.position, 
			$BackgroundEntities.get_cell_source_id(0, lightButton.position),
			Vector2i((lightButton.color & Lighting.LightingValueColorMask) - 1, (1 if lightButton.lit else 0) + (2 if lightButton.color & Lighting.LightingValue.Shadow else 0)),
		);
	
		$Wiring.setInput(lightButton.position, lightButton.lit);	
	
	for door : Door in doors:
		var open = $Wiring.getOuput(door.position);
		
		if (door.open == open): continue;
		door.open = open;
		postLightingUpdateNeeded = true;
	
		if (!door.open):
			$Entities.set_cell(
				0, door.position, 
				0,
				Vector2i((door.color & Lighting.LightingValueColorMask) + 8, 1 if door.color & Lighting.LightingValueShadowMask else 0),
			);
			$BackgroundEntities.set_cell(0, door.position);
		else:
			$BackgroundEntities.set_cell(
				0, door.position, 
				0,
				Vector2i((door.color & Lighting.LightingValueColorMask) + 6, 1 if door.color & Lighting.LightingValueShadowMask else 0),
			);
			$Entities.set_cell(0, door.position);
	
	if (postLightingUpdateNeeded):
		$Lighting.updateLighting();
	
func _ready():
	registerLighting();
	updateLighting();
	
	# Ignore setup states.
	activeState.clear();
	
func _process(delta):
	if (animationProcessing): 
		processAnimation(delta);
	else: 
		processInput();

var inputMovementLastPrioritizedY : bool = false;
func processInput():
	# Undo button.
	if (Input.is_action_just_pressed("player_undo")):
		statePop();
		return;
	
	# Restart button.
	if (Input.is_action_just_pressed("player_restart")):
		stateUnwind();
		return;
	
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
	
	# Get player information.
	var playerSource : int = $Entities.get_cell_source_id(0, playerPos);
	var playerAtlas : Vector2i = $Entities.get_cell_atlas_coords(0, playerPos);
	if (movement.y == -1): playerAtlas.y = 0;
	elif (movement.x == 1): playerAtlas.y = 1;
	elif (movement.y == 1): playerAtlas.y = 2;
	elif (movement.x == -1): playerAtlas.y = 3;
	
	# Check for wall.
	var targetPos : Vector2i = playerPos + movement;
	if (checkIfWall(targetPos)): return
	
	# Make sure an entity isnt in the way.
	if (checkIfEntity(targetPos)): 
		if (!isEntityTypePushable(getEntityTileType(targetPos))): 
			return;
		
		# Check if entity is blocked.
		var entityTargetPos : Vector2i = targetPos + movement;
		if (checkIfWall(entityTargetPos) || (checkIfEntity(entityTargetPos) && isEntityTypeSolid(getEntityTileType(entityTargetPos)))):
			return;
		
		# Set animation data.
		var entitySource : int = $Entities.get_cell_source_id(0, targetPos);
		var entityAtlas : Vector2i = $Entities.get_cell_atlas_coords(0, targetPos);
		$Entities.set_cell(0, targetPos);
		$Animation.set_cell(0, targetPos, entitySource, entityAtlas);
		
		match (getEntityTypeFromAtlas(entityAtlas)):
			EntityTileType.EntityTileType_Light:
				$Lighting.disableEmitter(targetPos);
				
				if (!(entityAtlas.y == playerAtlas.y || entityAtlas.y == ((playerAtlas.y + 2) % 4))):
					updateLighting();
	
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
	
	var affectedCellPositions : Array[Vector2i] = [];
	
	# Copy animation tilemap to entities.
	for x in range(animationRect.size.x):
		for y in range(animationRect.size.y):
			var pos : Vector2i = animationRect.position + Vector2i(x, y);
			affectedCellPositions.push_back(pos);
			if ($Animation.get_cell_source_id(0, pos) != -1):
				var atlas : Vector2i = $Animation.get_cell_atlas_coords(0, pos);
				$Entities.set_cell(
					0, pos + animationTileTargetOffset, 
					$Animation.get_cell_source_id(0, pos), 
					atlas
				);
				var entityType : EntityTileType = getEntityTypeFromAtlas(atlas);
				onEntityMove(entityType, pos, pos + animationTileTargetOffset);
	# Clear animation tilemap.
	$Animation.clear();
	
	stateAddMovement(animationTileTargetOffset, affectedCellPositions);


# Honestly, should've thought about this earlier. 
# So here it is,, in the big ol' main file.

var states : Array[Array] = []
var activeState : Array[Dictionary] = []

enum StateType {
	StateType_Movement,
	StateType_Wiring,
};

func stateGotoNext():
	states.push_back(activeState);
	activeState = [];
	updateMoveCountText();

var stateTracking : bool = true;
func statePop():
	if (states.size() <= 0): return;
	
	activeState.append_array(states.pop_back());
	
	stateTracking = false;
	for state : Dictionary in activeState:
		match (state["type"]):
			StateType.StateType_Movement:
				var movement : Vector2i = state["movement"];
				for affected : Vector2i in state["affectedTiles"]:
					var targetPos : Vector2i = affected + movement;
					var atlasPos : Vector2i = $Entities.get_cell_atlas_coords(0, targetPos);
					if (getEntityTypeFromAtlas(atlasPos) == EntityTileType.EntityTileType_Player):
						if (movement.y == -1): atlasPos.y = 0;
						elif (movement.x == 1): atlasPos.y = 1;
						elif (movement.y == 1): atlasPos.y = 2;
						elif (movement.x == -1): atlasPos.y = 3;
					
					$Animation.set_cell(
						0, affected, 
						$Entities.get_cell_source_id(0, targetPos),
						atlasPos
					);
					$Entities.set_cell(0, targetPos)
					
				var animationRect : Rect2i = $Animation.get_used_rect();
				for x in range(animationRect.size.x):
					for y in range(animationRect.size.y):
						var pos : Vector2i = animationRect.position + Vector2i(x, y);
						if ($Animation.get_cell_source_id(0, pos) != -1):
							var atlas : Vector2i = $Animation.get_cell_atlas_coords(0, pos);
							$Entities.set_cell(
								0, pos, 
								$Animation.get_cell_source_id(0, pos), 
								atlas
							);
							var entityType : EntityTileType = getEntityTypeFromAtlas(atlas);
							onEntityMove(entityType, pos + state["movement"], pos);
				$Animation.clear();
				
			StateType.StateType_Wiring:
				$Wiring.setInput(state["pos"], !state["state"]);

	activeState = [];

	# Just to make sure everything has settled.
	for i : int in range(5):
		updateLighting();
	
	stateTracking = true;
	updateMoveCountText();

func stateUnwind():
	# This is cursed and i think its hilarious
	while (!states.is_empty()): 
		statePop();

func stateAddMovement(movement : Vector2i, affectedTiles : Array[Vector2i]):
	if (!stateTracking): return;
	
	activeState.push_back({
		"type": StateType.StateType_Movement,
		"movement": movement,
		"affectedTiles": affectedTiles
	});
	stateGotoNext();
	
func updateMoveCountText(): 
	$"../Stats/Move Count".text = "Move Count: " + str(states.size());
	
func stateAddWiring(pos : Vector2i, state : bool):
	if (!stateTracking): return;
	
	activeState.push_back({
		"type": StateType.StateType_Wiring,
		"pos": pos,
		"state": state,
	});


