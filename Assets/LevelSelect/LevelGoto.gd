extends Button

var scenePath : String = "";
func setLevel(levelName : String, _scenePath : String):
	self.text = levelName;
	scenePath = _scenePath;
	
func onGotoLevel():
	if (scenePath == ""): return;
	get_tree().change_scene_to_file(scenePath);
