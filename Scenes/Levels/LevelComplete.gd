extends CanvasLayer

func _ready():
	var levelName : String = $"../".name;
	var artefactPath : String = ArtefactConfig.getLevelArtefactPath(levelName);
	if (!ResourceLoader.exists(artefactPath)): return;
	$Margin/Panel/VBox/Artefact.texture = ResourceLoader.load(artefactPath);
	
	var artefactName: String = ArtefactConfig.getLevelArtefactName(artefactPath);
	if (artefactName.contains("\n")):
		$Margin/Panel/VBox/VBox/Background/ArtefactName.add_theme_font_size_override("font_size", 35);
		artefactName = artefactName.replace("\n", " ");
	$Margin/Panel/VBox/VBox/Background/ArtefactName.text = "- " + artefactName + " -";
	
func levelComplete():
	visible = true;

func goBack():
	$"../".gotoLevelSelect(true);
