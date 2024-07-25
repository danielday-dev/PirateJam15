extends Node2D

func _ready():
	var tileSize = $Walls.tile_set.tile_size;
	var offset = Vector2($Walls.get_used_rect().position * tileSize);
	var size = Vector2($Walls.get_used_rect().size * tileSize) ;
	$Camera.global_position = $Walls.global_position + (size / 2.0) + offset;
	$Camera.zoom = Vector2(get_viewport_rect().size) / (size - (tileSize * 2.0));

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
