extends CanvasLayer

@export var splashTime : float = 3;

@export var splashImages : Array[Texture];

@export_file("*.tscn") var nextScene : String;

var remainingSplash : float = 0.0;
var activeSplash : int = -1;
func _process(delta):
	if (remainingSplash <= 0.0):
		cycleToNextSplash();
	else:
		remainingSplash -= delta;
	
	if (activeSplash >= splashImages.size()):
		if (nextScene):
			get_tree().change_scene_to_file(nextScene);#
		else:
			$ActiveLogo.visible = false;
	else:
		$ActiveLogo.texture = splashImages[activeSplash];
	
func cycleToNextSplash():
	activeSplash += 1;
	remainingSplash = splashTime;
		
func _input(event):
	if (event.is_pressed() && !event.is_echo()):
		cycleToNextSplash();
