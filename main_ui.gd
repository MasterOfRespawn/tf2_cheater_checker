extends Control

var API_KEY := ""

func _ready():
	load_api_key()
	%FileMenu.get_child(0, true).id_pressed.connect(_on_file_menu_selected)

func load_api_key():
	var file = FileAccess.open("./key.txt", FileAccess.READ)
	if file != null:
		var line = file.get_as_text().split("\n")[0]
		%KeyPopup/CenterContainer/HBoxContainer/KeyLineEdit.set_text(line)
		API_KEY=line
		file.close()

func save_api_key(key):
	var file = FileAccess.open("./key.txt", FileAccess.WRITE)
	if file != null:
		file.store_string(key)
		API_KEY=key
	file.close()

func _on_file_menu_selected(index: int):
	if index == 0: get_tree().quit(0)
	elif index == 1: %KeyPopup.popup_centered()


func _on_key_line_edit_text_changed(new_text):
	save_api_key(new_text)

func _on_key_line_edit_text_submitted(new_text):
	%KeyPopup.hide()
	_on_key_line_edit_text_changed(new_text)
