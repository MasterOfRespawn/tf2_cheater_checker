extends Control

func _ready():
	Key.load_api_key()
	%FileMenu.get_child(0, true).id_pressed.connect(_on_file_menu_selected)
	%PlayerMenu.get_child(0, true).id_pressed.connect(_on_player_menu_selected)
	
	var args = OS.get_cmdline_user_args()
	if len(args) > 0:
		if Key.API_KEY == "":
			printerr("ADD API KEY FIRST!")
			get_tree().quit()
		Key.HEADLESS = true
		Key.LOAD_FRIENDS = false
		Key.HEADLESS_TODO = len(args)
		#print(args)
		for arg in args:
			#print(arg)
			_on_steam_id_edit_text_submitted(arg)
			await get_tree().create_timer(1).timeout


func _on_file_menu_selected(index: int):
	if index == 0: get_tree().quit(0)
	elif index == 1: Key.show_interface()

func _on_player_menu_selected(index: int):
	if index == 0: $idPopup.popup_centered()
	elif index == 1: $urlPopup.popup_centered()

func _test_request_completed(result, response_code, headers, body):
	print(result)
	print(response_code)
	print(headers)
	print(body.get_string_from_utf8())


func _on_steam_url_edit_text_submitted(new_text):
	%Players.add_child(load("res://player_info.tscn").instantiate())
	%Players.get_child(-1).initialize_by_name(new_text)
	$urlPopup.hide()

func _on_url_popup_confirmed():
	_on_steam_url_edit_text_submitted(%steamURLEdit.text)

func _on_steam_id_edit_text_submitted(new_text):
	%Players.add_child(load("res://player_info.tscn").instantiate())
	%Players.get_child(-1).initialize(new_text)
	$idPopup.hide()

func _on_id_popup_confirmed():
	_on_steam_id_edit_text_submitted(%steamIDEdit.text)


func _on_friend_button_toggled(toggled_on):
	Key.LOAD_FRIENDS = toggled_on
