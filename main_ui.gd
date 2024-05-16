extends Control

func _ready():
	%FileMenu.get_child(0, true).id_pressed.connect(_on_file_menu_selected)

func _on_file_menu_selected(index: int):
	if index == 0: get_tree().quit(0)
