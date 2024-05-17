extends Control

func _ready():
	#%http.request_completed.connect(_test_request_completed)
	#%http.request("https://api.steampowered.com/ISteamWebAPIUtil/GetSupportedAPIList/v1/")
	Key.load_api_key()
	%FileMenu.get_child(0, true).id_pressed.connect(_on_file_menu_selected)
	%PlayerMenu.get_child(0, true).id_pressed.connect(_on_player_menu_selected)


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

func _on_url_popup_confirmed():
	_on_steam_url_edit_text_submitted(%steamURLEdit.text)

func _on_steam_id_edit_text_submitted(new_text):
	%Players.add_child(load("res://player_info.tscn").instantiate())
	%Players.get_child(-1).initialize(new_text)

func _on_id_popup_confirmed():
	_on_steam_id_edit_text_submitted(%steamIDEdit.text)
