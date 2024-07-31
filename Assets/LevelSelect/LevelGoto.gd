extends Button

var scenePath : String = "";
func setLevel(levelName : String, _scenePath : String):
	self.text = levelName;
	scenePath = _scenePath;
	
	var artefactPath : String = ArtefactConfig.getLevelArtefactPath(levelName);
	if (ResourceLoader.exists(artefactPath)):
		$Artefact.texture = ResourceLoader.load(artefactPath);
	
func onGotoLevel():
	if (scenePath == ""): return;
	var scene : PackedScene = ResourceLoader.load(scenePath);
	var instance : Node2D = scene.instantiate();
	instance.name = self.text;
	get_tree().root.add_child(instance);
	LeaderBoard.levelName = self.text;
	get_tree().root.get_child(1).get_child(2).get_child(1).release_focus();

func showArtefact():
	$Artefact.visible = true;
