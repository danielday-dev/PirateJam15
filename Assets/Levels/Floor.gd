@tool
extends TileMap

@export var generateFloor : bool = false:
	set(value):
		if (value):
			generate();
		
func generate():
	if (!Engine.is_editor_hint()): return;
	
	clear();
	
	var wallRect : Rect2i = $"../Walls".get_used_rect();
	for x in range(wallRect.size.x):
		for y in range(wallRect.size.y):
			var pos : Vector2i = Vector2i(x, y) + wallRect.position;
			set_cell(0, pos, 0, Vector2i((x + y) % 2, randi_range(0, 3)));
