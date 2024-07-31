extends TabContainer
class_name LeaderBoard;

static var username : String = "";
static var levelName : String = "1";
static var levelScore : int = 1;

var getRequest : HTTPRequest;
var submitRequest : HTTPRequest;
func _ready():
	getRequest = HTTPRequest.new()
	add_child(getRequest)
	getRequest.request_completed.connect(self.processRequest)
	submitRequest = HTTPRequest.new()
	add_child(submitRequest)
	submitRequest.request_completed.connect(self.processRequest)

func visibilityChanged():
	if (!visible): return;
	
	if (username == ""): 
		remove_child($Personal);
		getLeaderBoardInformation();
	else:
		submitScore();
	
func processRequest(result, responseCode, headers, body):
	var json : JSON = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data();
	print(response);
	if (response == null): return;
	
	if (response.has("success")):
		if (response["success"]):
			getLeaderBoardInformation();
	
	if (response.has("global")):
		clearLeaderBoard($Global/Board);		
		for entry in response["global"]:
			addLeaderBoardEntry($Global/Board, entry["rank"], entry["name"], entry["score"]);
		
	if (response.has("personal")):
		clearLeaderBoard($Personal/Board);		
		for entry in response["personal"]:
			addLeaderBoardEntry($Personal/Board, entry["rank"], entry["name"], entry["score"]);

func submitScore():
	var body = JSON.new().stringify({ 
		"level": levelName,
		"name": username,
		"score": levelScore, 
		"key": "PLEASE DONT BE A GREMLIN AND CHEAT THE SYSTEM,, NAUGHTY FELLA",
	});
	var error = submitRequest.request("https://piratejam15.jawdan.dev/postLeaderboard/", [ "Content-Type: application/json" ], HTTPClient.METHOD_POST, body)
	if error != OK: push_error("An error occurred in the HTTP request.")

func getLeaderBoardInformation():
	var body = JSON.new().stringify({ 
		"level": levelName,
		"name": username,
		"key": "THIS ONE ISNT SO BAD TO SORTA USE,,",
	});
	var error = getRequest.request("https://piratejam15.jawdan.dev/getLeaderboard/", [ "Content-Type: application/json" ], HTTPClient.METHOD_POST, body)
	if error != OK: push_error("An error occurred in the HTTP request.")
	
func addLeaderBoardEntry(board : Control, rank : int, name : String, score : int):
	if (board == null): return;
	
	var rankElement : Control = board.get_child(0);
	var nameElement : Control = board.get_child(2);
	var scoreElement : Control = board.get_child(4);
	
	addLabel(rankElement, str(rank));
	addLabel(nameElement, name);
	addLabel(scoreElement, str(score));
	
func addLabel(element : Control, text : String):
	var label : Label = Label.new();
	label.text = text;
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
	element.add_child(label);	

func clearLeaderBoard(board : Control):
	if (board == null): return;
	
	var targets : Array[Control] = [ board.get_child(0), board.get_child(2), board.get_child(4) ];
	for target : Control in targets:
		if (target == null): continue;
		while (target.get_child_count() > 2):
			target.remove_child(target.get_children().back());
