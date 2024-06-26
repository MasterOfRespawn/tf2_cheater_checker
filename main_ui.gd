extends Control

var timeout = -1.0

func _ready():
	Key.load_api_key()
	%FileMenu.get_child(0, true).id_pressed.connect(_on_file_menu_selected)
	%PlayerMenu.get_child(0, true).id_pressed.connect(_on_player_menu_selected)
	%GotoButton.get_popup().id_pressed.connect(_on_goto_menu_selected)
	
	var args := OS.get_cmdline_user_args()
	if len(args) > 0:
		if Key.API_KEY == "":
			printerr("ADD API KEY FIRST!")
			get_tree().quit()
		print(" --- tf2ccOut --- ")
		Key.HEADLESS = true
		Key.LOAD_FRIENDS = false
		#Key.RECURSIVE = OS.get_cmdline_args().has("--recursive")
		for arg in args:
			for id in Tools.extract_steam_ids_from_text(arg):
				Key.CHECKS_TODO.append(id)
	args = OS.get_cmdline_args()
	if len(args) > 0 and !Key.HEADLESS:
		print("TF2CC - usage")
		print(OS.get_executable_path() + " [--headless] [--short] -- {IDs}")
		print("--headless - disable window")
		print("--short    - print X on every active suspicion check instead of true")
		print("   {IDs}   - space seperated list of steam profile ids (64bit int)")

func _process(delta):
	if len(Key.CHECKS_TODO) != 0:
		timeout -= delta
		if timeout < 0:
			timeout = 1
			var id = Key.CHECKS_TODO[0]
			%Players.add_child(load("res://player_info.tscn").instantiate())
			var index = 0
			while index != -1:
				Key.CHECKS_TODO.remove_at(index)
				index = Key.CHECKS_TODO.find(id)
			%Players.get_child(-1).initialize(id)

func _on_file_menu_selected(index: int):
	if index == 0: get_tree().quit(0)
	elif index == 1: Key.show_interface()

func _on_player_menu_selected(index: int):
	if index == 0: $idPopup.popup_centered()
	elif index == 1: $urlPopup.popup_centered()
	elif index == 2: $batchPopup.popup_centered()

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


func _on_batch_popup_confirmed():
	$batchPopup.hide()
	for id in Tools.extract_steam_ids_from_text(%steamIDBatchEdit.text):
		_on_steam_id_edit_text_submitted(id)
		await get_tree().create_timer(2).timeout


func _on_players_node_changed(_node = null):
	await get_tree().create_timer(1).timeout
	var menu: PopupMenu = %GotoButton.get_popup()
	menu.clear()
	for child in %Players.get_children():
		menu.add_item(child.name)
	
	%GotoButton.visible = %Players.get_child_count() != 0

func _on_goto_menu_selected(index: int):
	%Players.current_tab = index


func _on_scan_achievement_times_toggled(toggled_on):
	Key.SCAN_ACHIEVEMENT_TIMES = toggled_on
