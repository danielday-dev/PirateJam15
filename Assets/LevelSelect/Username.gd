extends LineEdit

const allowedCharacters : String = "ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxyz_1234567890";
func _onTextChanged(new_text):
	var cursorPos = caret_column;
	
	for i in range(len(text)):
		if (!allowedCharacters.contains(text[i])):
			text = text.erase(i);
			caret_column = min(len(text), cursorPos);
			_onTextChanged(text);
			break;
			
	LeaderBoard.username = text;

func _onMouseExit():
	release_focus();
