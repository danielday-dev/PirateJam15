extends Node2D
class_name Lighting;

const tileScale : float = 36.0;

enum Direction {
	Direction_Up,
	Direction_Right,
	Direction_Down,
	Direction_Left,
};
func flipDirection(direction : Direction) -> Direction:
	return (direction + 2) % 4;

class Emitter:
	var position : Vector2i;
	var color : int;
	var direction : Direction;
	func _init(_position : Vector2i, _color : int, _direction : Direction):
		position = _position;
		color = _color;
		direction = _direction;
var emitters : Array[Emitter] = [];

func checkIfSolid(pos : Vector2i) -> bool:
	if (get_parent().checkIfWall(pos)): return true;
	var entityType : ObjectProcess.EntityTileType = get_parent().getEntityTileType(pos);
	return get_parent().isEntityTypeSolid(entityType);
	
enum LightingValue {
	Red = 1 << 0,
	Green = 1 << 1,
	Blue = 1 << 2,
};
func getLightingColor(lighting : int) -> Color:
	var color : Color = Color.BLACK;
	if (lighting & LightingValue.Red): color.r = 1.0;
	if (lighting & LightingValue.Green): color.g = 1.0;
	if (lighting & LightingValue.Blue): color.b = 1.0;
	return color;

class LightingInformation:
	var isInput : bool;
	var color : int;
	var direction : Direction;
	func _init(_direction : Direction):
		isInput = false;
		color = 0;
		direction = _direction;

var lightingData : Dictionary = {};
func updateLighting(): 
	lightingData.clear();
	
	print("So we got here?");
	
	for emitter in emitters:
		var pos : Vector2i = emitter.position;
		
		var color : int = emitter.color;
		var maxLength : int = 100;
		while (maxLength > 0):
			maxLength -= 1;
			
			match (emitter.direction):
				Direction.Direction_Up: pos.y -= 1;
				Direction.Direction_Right: pos.x += 1;
				Direction.Direction_Down: pos.y += 1;
				Direction.Direction_Left: pos.x -= 1;
			
			if (checkIfSolid(pos)):
				break;
			
			var lightingDataPos : Array = [
				LightingInformation.new(Direction.Direction_Up),
				LightingInformation.new(Direction.Direction_Right),
				LightingInformation.new(Direction.Direction_Down),
				LightingInformation.new(Direction.Direction_Left),
			] if !lightingData.has(pos) else lightingData[pos];
			
			lightingDataPos[emitter.direction].color |= color;
			lightingDataPos[flipDirection(emitter.direction)].color |= color;
			lightingDataPos[flipDirection(emitter.direction)].isInput = true;
			
			if (lightingData.has(pos)):
				color = propagateLighting(pos, 0, flipDirection(emitter.direction));
			else:
				lightingData[pos] = lightingDataPos;
	
	queue_redraw();

func propagateLighting(pos : Vector2i, color : int, fromDirection : Direction) -> int:
	if (!lightingData.has(pos)): 
		return 0;
	var lightingDataPos : Array = lightingData[pos];
	
	if (color == 0):
		var totalColor : int = 0;
		for lightingInfo : LightingInformation in lightingDataPos:
			if (lightingInfo.isInput): 
				totalColor |= lightingInfo.color;
		color = totalColor;
	if (color == 0): return 0;
	
	
	var totalColor : int = 0;
	var propogateDirections : Array[Direction] = [];
	for lightingInfo : LightingInformation in lightingDataPos:
		if (!lightingInfo.isInput): continue;
		totalColor |= lightingInfo.color;
		
		propogateDirections.push_back(flipDirection(lightingInfo.direction));

	if (totalColor != color):
		lightingDataPos[fromDirection].color = color;
		totalColor |= color;

	# Propogate I guess.
	for direction : Direction in propogateDirections:
		var lightingInfo : LightingInformation = lightingDataPos[direction];
		if (lightingInfo.isInput || lightingInfo.color == totalColor): continue;
			
		
		lightingInfo.color = totalColor;
		match (lightingInfo.direction):
			Direction.Direction_Up: propagateLighting(pos + Vector2i(0, -1), totalColor, Direction.Direction_Down);
			Direction.Direction_Right: propagateLighting(pos + Vector2i(1, 0), totalColor, Direction.Direction_Left);
			Direction.Direction_Down: propagateLighting(pos + Vector2i(0, 1), totalColor, Direction.Direction_Up);
			Direction.Direction_Left: propagateLighting(pos + Vector2i(-1, 0), totalColor, Direction.Direction_Right);
	return totalColor;

func _ready():
	updateLighting();

func addEmitter(emitter : Emitter) -> bool:
	for e : Emitter in emitters:
		if (e.position == emitter.position):
			return false;
	
	emitters.push_back(emitter);
	return true;
	
func removeEmitter(emitterPos : Vector2i):
	for i : int in range(len(emitters)):
		if (emitters[i].position == emitterPos):
			emitters.remove_at(i);
			break;
	
func moveEmitter(emitterPos : Vector2i, newPos : Vector2i):
	var emitter : Emitter = null;
	for e : Emitter in emitters:
		if (e.position == emitterPos):
			emitter = e;
			break;
	
	if (addEmitter(Emitter.new(newPos, emitter.color, emitter.direction))):
		removeEmitter(emitterPos);
	
func clearEmitters():
	emitters.clear();
	
func _draw():
	const lightingWidth = 8;
	
	for pos in lightingData:
		var midPoint : Vector2 = Vector2(pos) + Vector2(0.5, 0.5);
		var midLighting : int = 0;
		for lightingInfo : LightingInformation in lightingData[pos]:
			if (!lightingInfo.color): continue;
			
			var sidePos : Vector2 = Vector2(pos);
			match (lightingInfo.direction):
				Direction.Direction_Up: 
					sidePos.x += 0.5;
				Direction.Direction_Right: 
					sidePos.x += 1.0; 
					sidePos.y += 0.5;
				Direction.Direction_Down: 
					sidePos.x += 0.5; 
					sidePos.y += 1.0;
				Direction.Direction_Left: 
					sidePos.y += 0.5;
			
			if (lightingInfo.isInput):
				midLighting |= lightingInfo.color;
			
			draw_line(
				sidePos * tileScale, 
				midPoint * tileScale, 
				getLightingColor(lightingInfo.color), lightingWidth, false
			);
			
		draw_line(
			(midPoint * tileScale) + Vector2(0, lightingWidth / 2), 
			(midPoint * tileScale) + Vector2(0, -lightingWidth / 2), 
			getLightingColor(midLighting), lightingWidth, false
		);
