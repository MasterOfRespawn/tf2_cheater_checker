extends HBoxContainer

var id := ""
# 0 uninitialized
# 1 profile_name
# 2 profile icon
# 3 done
var state = 0

var picture_url := ""
var retries := 0

signal FRIEND_COMPLETELY_LOADED

func _ready():
	self.add_child(HTTPRequest.new())
	self.get_child(0).request_completed.connect(_http_request_completed)
	self.add_child(VBoxContainer.new())
	self.get_child(1).add_child(TextureRect.new())
	self.get_child(1).get_child(0).set_stretch_mode(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	self.get_child(1).add_child(Button.new())
	self.get_child(1).get_child(1).set_text("view")
	self.get_child(1).get_child(1).button_up.connect(_view_button_up)
	self.add_child(VBoxContainer.new())
	self.get_child(2).add_child(LineEdit.new())
	self.get_child(2).add_child(LineEdit.new())
	self.get_child(2).add_child(Label.new())
	self.get_child(2).get_child(0).editable = false
	self.get_child(2).get_child(1).editable = false
	

func initialize(steam_id: String, relationship: String, time: int, delay: int):
	state = 1
	id = steam_id
	self.get_child(2).get_child(1).set_text(id)
	self.get_child(2).get_child(2).set_text(relationship + " since " + Time.get_datetime_string_from_unix_time(time))
	if Key.LOAD_FRIENDS:
		await get_tree().create_timer(delay).timeout
		self.get_child(0).request("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?" + Key.get_formatted() + "&steamids=" + id)
	else:
		self.get_child(2).get_child(0).hide()

func _http_request_completed(_result, _response, _header, data):
	if state == 1:
		@warning_ignore("shadowed_global_identifier")
		var str = data.get_string_from_utf8()
		var json = JSON.new()
		if json.parse(str) == 0:
			var dat = json.data
			self.get_child(2).get_child(0).set_text(dat["response"]["players"][0]["personaname"])
			picture_url = dat["response"]["players"][0]["avatarmedium"]
			self.get_child(0).request(picture_url)
			state = 2
		else:
			print("FRIEND PROFILE REQUEST ERROR (RETRYING SOON)[" + id + "] - retry" + str(retries))
			await get_tree().create_timer(0.5 + (retries*2)).timeout
			retries += 1
			if retries == 10:
				print("TOO MUCH TRAFFIC, GIVING UP [" + id + "]")
				return
			self.get_child(0).request("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?" + Key.get_formatted() + "&steamids=" + id)
	elif state == 2:
		var img = Image.new()
		if img.load_jpg_from_buffer(data) == OK:
			self.get_child(1).get_child(0).set_texture(ImageTexture.create_from_image(img))
		else:
			print("INVALID AVATAR [" + id + "]")
		state = 3
		self.get_child(0).queue_free()
		FRIEND_COMPLETELY_LOADED.emit()

func _view_button_up():
	get_tree().current_scene._on_steam_id_edit_text_submitted(id)
