@tool
extends Resource
class_name WireConnection;

signal onUpdate;

@export var start : Vector2i:
	set(value):
		start = value;
		onUpdate.emit();
@export var end : Vector2i:
	set(value):
		end = value;
		onUpdate.emit();

@export var color : Color = Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0)):
	set(value):
		color = value;
		onUpdate.emit();
