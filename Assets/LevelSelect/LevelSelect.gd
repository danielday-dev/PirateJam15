extends Control

@export var levelGoto : PackedScene = null

# https://www.reddit.com/r/godot/comments/k1t53k/getting_tscn_children_from_levels_folder/
func getFilePathsByExtension(directoryPath: String, extension: String, recursive: bool = true) -> Array:
	var dir = DirAccess.open(directoryPath);
	if !dir:
		printerr("Warning: could not open directory: ", directoryPath)
		return []

	if dir.list_dir_begin() != OK:
		printerr("Warning: could not list contents of: ", directoryPath)
		return []

	var filePaths = []
	var fileName = dir.get_next()

	while fileName != "":
		if dir.current_is_dir():
			if recursive:
				var dirPath = dir.get_current_dir() + "/" + fileName
				filePaths += getFilePathsByExtension(dirPath, extension, recursive)
		elif fileName.get_extension() == extension:
			var filePath = dir.get_current_dir() + "/" + fileName;
			filePaths.append(filePath);
		fileName = dir.get_next()

	return filePaths

var gotos : Dictionary = {};
func _ready():
	if (levelGoto == null):
		printerr("LevelGoto instance not specified.");
		return;
	
	# Get levels.
	var levelPaths = getFilePathsByExtension("res://Scenes/Levels", "tscn", false);
	var levelNames = levelPaths.map(func(path : String):
		var start = path.rfind("/") + 1;
		var end = path.rfind(".");
		return path.substr(start, end - start);
	);
	
	# Add level buttons.
	for i in range(min(levelPaths.size(), levelNames.size())):
		var instance : Control = levelGoto.instantiate();
		instance.setLevel(levelNames[i], levelPaths[i]);
		$VBox/Grid.add_child(instance);
		gotos[levelNames[i]] = instance;

func completeLevel(levelName : String):
	if (!gotos.has(levelName)): return;
	gotos[levelName].showArtefact();
	
