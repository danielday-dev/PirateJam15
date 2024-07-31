extends Node
class_name ArtefactConfig;

static func getLevelArtefactPath(levelName : String) -> String:
	match (levelName):
		"1": return "res://Assets/Artefacts/0.png";
		"2": return "res://Assets/Artefacts/1.png";
		"3": return "res://Assets/Artefacts/2.png";
		"4": return "res://Assets/Artefacts/3.png";
		"5": return "res://Assets/Artefacts/4.png";
		"6": return "res://Assets/Artefacts/5.png";
		"7": return "res://Assets/Artefacts/6.png";
		"8": return "res://Assets/Artefacts/7.png";
		"9": return "res://Assets/Artefacts/8.png";
		"Fin": return "res://Assets/Artefacts/10.png";
	return "res://Assets/Artefacts/11.png";

static func getLevelArtefactName(path : String) -> String:
	match (path):
		"res://Assets/Artefacts/0.png": return "Jem";
		"res://Assets/Artefacts/1.png": return "Cool ass sword.";
		"res://Assets/Artefacts/2.png": return "CUTE LIL' PLUSH";
		"res://Assets/Artefacts/3.png": return "Stick of... Gold?";
		"res://Assets/Artefacts/4.png": return "Somebody has\nmy rabbit?!";
		"res://Assets/Artefacts/5.png": return "Jar of sand";
		"res://Assets/Artefacts/6.png": return "Divergentleman";
		"res://Assets/Artefacts/7.png": return "Someone Else's\nSelf Portrait";
		"res://Assets/Artefacts/8.png": return "Fool's Luck";
		"res://Assets/Artefacts/9.png": return "Glizz";
		"res://Assets/Artefacts/10.png": return "Anxiety flavoured\nPop Rocks";
		"res://Assets/Artefacts/11.png": return "A job well done.";
	return "???"
