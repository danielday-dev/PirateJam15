@tool
extends Node2D
class_name Wiring;

@export var connections : Array[WireConnection]:
	set(val):
		connections = val;
		for connection : WireConnection in connections:
			if (connection != null && !connection.onUpdate.is_connected(_onConnectionChanged)):
				connection.onUpdate.connect(_onConnectionChanged);
		queue_redraw();
func _onConnectionChanged():
	queue_redraw();

class InputCell:
	var state : bool;
	var outputPos : Array[Vector2i];
	
	func _init(_outputPos : Vector2i, outputCells : Dictionary):
		state = false;
		outputPos = [];
		addOutput(_outputPos, outputCells);
	
	func addOutput(_outputPos : Vector2i, outputCells : Dictionary):
		outputPos.push_back(_outputPos);
		
		if (outputCells.has(_outputPos)):
			outputCells[_outputPos].remainingInputs += 1;
		else:
			outputCells[_outputPos] = OutputCell.new();
	
	func setState(_state : bool, outputCells : Dictionary):
		if (state == _state): return;
		
		state = _state;
		
		for pos : Vector2i in outputPos:
			if (state): outputCells[pos].remainingInputs -= 1;
			else: outputCells[pos].remainingInputs += 1;
		
class OutputCell:
	var remainingInputs : int;
	func _init():
		remainingInputs = 1;

	func getState():
		return remainingInputs <= 0;
		
var inputCells : Dictionary;
var outputCells : Dictionary;
func _ready():
	if (Engine.is_editor_hint()): return;
	
	for connection : WireConnection in connections:
		if (connection == null): continue;
		
		if (inputCells.has(connection.start)):
			inputCells[connection.start].addOutput(connection.end, outputCells);
		else:
			inputCells[connection.start] = InputCell.new(connection.end, outputCells);
	
func setInput(pos : Vector2i, state : bool) -> void:
	if (!inputCells.has(pos)): return;
	inputCells[pos].setState(state, outputCells);

func getOuput(pos : Vector2i) -> bool:
	if (!outputCells.has(pos)): return false;
	return outputCells[pos].getState();

const tileScale : float = 36.0;
func _draw():
	if (!Engine.is_editor_hint()): return;
	
	for connection : WireConnection in connections:
		if (connection == null): continue;
		var centerOffset : Vector2 = Vector2.ONE * 0.5;
		var start : Vector2 = (Vector2(connection.start) + centerOffset) * tileScale;
		var end : Vector2 = (Vector2(connection.end) + centerOffset) * tileScale;
		
		draw_line(start, end, connection.color, 3);
		draw_circle(start, 9, Color(1.0, 0.0, 0.0, 0.4));
		draw_circle(start, 8, lerp(connection.color, Color.WHITE, 0.4));
		draw_circle(end, 9, Color(0.0, 1.0, 0.0, 0.4));
		draw_circle(end, 8, lerp(connection.color, Color.BLACK, 0.4));
