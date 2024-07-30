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
	var enabled : bool;
	var position : Vector2i;
	var color : int;
	var direction : Direction;
	func _init(_position : Vector2i, _color : int, _direction : Direction):
		enabled = true;
		position = _position;
		color = _color;
		direction = _direction;
		
var emitters : Array[Emitter] = [];

func checkIfSolid(pos : Vector2i) -> bool:
	if (get_parent().checkIfWall(pos)): return true;
	var entityType : ObjectProcess.EntityTileType = get_parent().getEntityTileType(pos);
	return get_parent().isEntityTypeSolid(entityType);
func checkIfShadowable(pos : Vector2i) -> bool:
	if (get_parent().checkIfWall(pos)): return false;
	var entityType : ObjectProcess.EntityTileType = get_parent().getEntityTileType(pos);
	return get_parent().isEntityTypeShadowable(entityType);
	
enum LightingValue {
	Red = 1 << 0,
	Green = 1 << 1,
	Blue = 1 << 2,
	Shadow = 1 << 3,
};
const LightingValueColorMask : int = LightingValue.Red | LightingValue.Green | LightingValue.Blue;
const LightingValueShadowMask : int = LightingValue.Shadow;
		
func getLightingColor(lighting : int) -> Color:
	var color : Color = Color.BLACK;
	if (lighting & LightingValue.Red): color.r = 1.0;
	if (lighting & LightingValue.Green): color.g = 1.0;
	if (lighting & LightingValue.Blue): color.b = 1.0;
	if (lighting & LightingValue.Shadow):
		color.r *= 0.5;
		color.g *= 0.5;
		color.b *= 0.5;
	return color;

class LightingInformation:
	var isInput : bool;
	var color : int;
	var direction : Direction;
	func _init(_direction : Direction):
		isInput = false;
		color = 0;
		direction = _direction;

class LightData:
	var color : int;
	var data : Array[LightingInformation];
	
	func _init():
		data = [
			LightingInformation.new(Direction.Direction_Up),
			LightingInformation.new(Direction.Direction_Right),
			LightingInformation.new(Direction.Direction_Down),
			LightingInformation.new(Direction.Direction_Left),
		];
		color = 0;
		
	func calculateTotalColor():		
		color = 0;
		var shadowColor : int = 0;
		for lightingInfo : LightingInformation in data:
			if (lightingInfo.isInput): 
				if (lightingInfo.color & LightingValueShadowMask): shadowColor |= lightingInfo.color;
				else: color |= lightingInfo.color & LightingValueColorMask;;
				
		if (color == 0 && shadowColor != 0):
			color = shadowColor;

var lightingData : Dictionary = {};
func updateLighting(): 
	lightingData.clear();
	
	# Handle Lighting.
	var endPoints : Dictionary = {};
	for emitter in emitters:
		if (!emitter.enabled): continue;
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
				if (checkIfShadowable(pos)):
					var arr : Array[Direction] = [];
					if (endPoints.has(pos)): arr = endPoints[pos];
					else: endPoints[pos] = arr;
					
					arr.push_back(emitter.direction);
				break;
			
			var lightingDataPos : LightData = LightData.new() if !lightingData.has(pos) else lightingData[pos];
			
			lightingDataPos.data[emitter.direction].color |= color;
			lightingDataPos.data[flipDirection(emitter.direction)].color |= color;
			lightingDataPos.data[flipDirection(emitter.direction)].isInput = true;
			
			if (lightingData.has(pos)):
				color = propagateLighting(pos, 0, flipDirection(emitter.direction));
			else:
				lightingDataPos.calculateTotalColor();
				lightingData[pos] = lightingDataPos;
	
	# Handle shadows.
	for endPos : Vector2i in endPoints:
		for direction : Direction in endPoints[endPos]:
			var pos : Vector2i = endPos;
			var originPos : Vector2i = endPos;
			match (direction):
				Direction.Direction_Up: originPos.y += 1;
				Direction.Direction_Right: originPos.x -= 1;
				Direction.Direction_Down: originPos.y -= 1;
				Direction.Direction_Left: originPos.x += 1;
			
			if (!lightingData.has(originPos)): continue;
			var color : int = lightingData[originPos].color | LightingValue.Shadow;
			
			var maxLength : int = 100;
			while (maxLength > 0):
				maxLength -= 1;
				
				match (direction):
					Direction.Direction_Up: pos.y -= 1;
					Direction.Direction_Right: pos.x += 1;
					Direction.Direction_Down: pos.y += 1;
					Direction.Direction_Left: pos.x -= 1;
				
				if (checkIfSolid(pos)):
					break;
	
				if (lightingData.has(pos)):
					var lightingDataPos : LightData = lightingData[pos];
					if (lightingDataPos.data[flipDirection(direction)].color): break;
					
					lightingDataPos.data[flipDirection(direction)].color |= color;
					lightingDataPos.data[flipDirection(direction)].isInput = true;
					lightingDataPos.calculateTotalColor();
					
					if (lightingDataPos.color & LightingValue.Shadow):
						lightingDataPos.data[direction].color |= color;
						color = propagateLighting(pos, 0, flipDirection(direction));
						pass;
					else:
						break;
				else:
					var lightingDataPos : LightData = LightData.new();
					lightingDataPos.data[direction].color |= color;
					lightingDataPos.data[flipDirection(direction)].color |= color;
					lightingDataPos.data[flipDirection(direction)].isInput = true;
					lightingDataPos.calculateTotalColor();
					lightingData[pos] = lightingDataPos;
	
	queue_redraw();

func propagateLighting(pos : Vector2i, color : int, fromDirection : Direction) -> int:
	if (!lightingData.has(pos)): 
		return 0;
	var lightingDataPos : LightData = lightingData[pos];
	
	lightingDataPos.calculateTotalColor();
	if (color == 0):
		color = lightingDataPos.color;
	if (color == 0): return 0;
	
	var propogateDirections : Array[Direction] = [];
	for lightingInfo : LightingInformation in lightingDataPos.data:
		if (!lightingInfo.isInput): continue;
		propogateDirections.push_back(flipDirection(lightingInfo.direction));

	var totalColor = lightingDataPos.color;
	if (totalColor != color):
		if (totalColor & LightingValueShadowMask != color & LightingValueShadowMask): return totalColor;
		
		lightingDataPos.data[fromDirection].color = color;
		totalColor |= color;

	# Propogate I guess.
	for direction : Direction in propogateDirections:
		var lightingInfo : LightingInformation = lightingDataPos.data[direction];
		if (lightingInfo.isInput || lightingInfo.color == totalColor): continue;
			
		
		lightingInfo.color = totalColor;
		match (lightingInfo.direction):
			Direction.Direction_Up: propagateLighting(pos + Vector2i(0, -1), totalColor, Direction.Direction_Down);
			Direction.Direction_Right: propagateLighting(pos + Vector2i(1, 0), totalColor, Direction.Direction_Left);
			Direction.Direction_Down: propagateLighting(pos + Vector2i(0, 1), totalColor, Direction.Direction_Up);
			Direction.Direction_Left: propagateLighting(pos + Vector2i(-1, 0), totalColor, Direction.Direction_Right);
			
		
	lightingDataPos.calculateTotalColor();
	return lightingDataPos.color;

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
	
func enableEmitter(emitterPos : Vector2i):
	for emitter : Emitter in emitters:
		if (emitter.position == emitterPos):
			emitter.enabled = true;
			break;
			
func disableEmitter(emitterPos : Vector2i):
	for emitter : Emitter in emitters:
		if (emitter.position == emitterPos):
			emitter.enabled = false;
			break;
	
func clearEmitters():
	emitters.clear();
	
func _draw():
	const lightingWidth = 8;
	
	for pos in lightingData:
		var midPoint : Vector2 = Vector2(pos) + Vector2(0.5, 0.5);
		var midLighting : int = 0;
		for lightingInfo : LightingInformation in lightingData[pos].data:
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
			
			draw_line(
				sidePos * tileScale, 
				midPoint * tileScale, 
				getLightingColor(lightingInfo.color), lightingWidth, false
			);
			
		draw_line(
			(midPoint * tileScale) + Vector2(0, lightingWidth / 2), 
			(midPoint * tileScale) + Vector2(0, -lightingWidth / 2), 
			getLightingColor(lightingData[pos].color), lightingWidth, false
		);
