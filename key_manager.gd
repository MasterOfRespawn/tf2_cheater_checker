extends Window

var API_KEY := ""
var LOAD_FRIENDS := true
var HEADLESS := false
var HEADLESS_TODO := 0

func load_api_key():
	var file = FileAccess.open("./key.txt", FileAccess.READ)
	if file != null:
		var line = file.get_as_text().split("\n")[0]
		$CenterContainer/HBoxContainer/KeyLineEdit.set_text(line)
		API_KEY=line
		file.close()

func save_api_key(key):
	var file = FileAccess.open("./key.txt", FileAccess.WRITE)
	if file != null:
		file.store_string(key)
		API_KEY=key
	file.close()

func get_key() -> String:
	return API_KEY

func get_formatted() -> String:
	return "key=" + API_KEY

func initialized() -> bool:
	return API_KEY != ""


func _on_key_line_edit_text_changed(new_text):
	save_api_key(new_text)

func _on_key_line_edit_text_submitted(new_text):
	self.hide()
	_on_key_line_edit_text_changed(new_text)

func show_interface():
	self.popup_centered()
