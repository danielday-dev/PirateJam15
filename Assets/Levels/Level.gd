extends Node2D

func _ready():
	var tileSize = $Objects/Walls.tile_set.tile_size;
	var offset = Vector2($Objects/Walls.get_used_rect().position * tileSize);
	var size = Vector2($Objects/Walls.get_used_rect().size * tileSize) ;
	$Camera.global_position = $Objects/Walls.global_position + (size / 2.0) + offset;
	var zoomRaw = Vector2(get_viewport_rect().size) / (size - (tileSize * 2.0));
	var zoom = min(zoomRaw.x, zoomRaw.y);
	$Camera.zoom = Vector2(zoom, zoom); 
