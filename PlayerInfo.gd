extends Control

const STEAM_URL := "https://api.steampowered.com/"
static var API_CALLS := PackedStringArray(["",
	"ISteamUser/ResolveVanityURL/v1/?",
	"ISteamUser/GetPlayerSummaries/v2/?",
	"",
	"ISteamUser/GetPlayerBans/v1/?",
])

# 0 uninitialized
# 1 resolve player name
# 2 base profile info
# 3 friend list
# 4 VAC bans
# 5 steam level / badges
# 6 recently played
# 100 player icon
# 255 complete
var id := ""
var profile_picture_url := ""

func initialize_by_name(steam_name: String):
	if !Key.initialized(): 
		self.queue_free()
		return
	id = steam_name
	%infostep.value = 1
	request_info()

func initialize(steam_id: String):
	if !Key.initialized(): 
		self.queue_free()
		return
	id = steam_id
	%infostep.value = 2
	request_info()

func request_info():
	print(%infostep.value)
	match %infostep.value:
		1.0: %http.request(STEAM_URL + API_CALLS[1] + Key.get_formatted() + "&vanityurl=" + id)
		2.0: %http.request(STEAM_URL + API_CALLS[2] + Key.get_formatted() + "&steamids=" + id)
		100.0: %http.request(profile_picture_url)
		255.0: 
			%infostep.visible = false
			return
		_: 
			push_error("UNREACHABLE STATE REQUEST: ", %infostep.value, "\n", self)

func handle_result(result_string):
	if %infostep.value == 100:
		print("TMP")
		var img = Image.new()
		var img_result = img.load_jpg_from_buffer(result_string)
		if img_result == 0:
			%PlayerIcon.set_texture(ImageTexture.create_from_image(img))
		else:
			push_warning("INVALID IMAGE RESULT: ", img_result)
		%infostep.value = 255
		request_info()
		return
	var result: Dictionary = JSON.parse_string(result_string.get_string_from_utf8())
	match %infostep.value:
		1.0:
			if result["response"]["success"] == 1:
				id = result["response"]["steamid"]
				%infostep.value += 1
				request_info()
			else:
				push_error("NONEXISTANT VANITY URL: ", id)
		2.0:
			%PlayerSteamID.set_text(id)
			if len(result["response"]["players"]) != 0:
				%PlayerName.set_text(result["response"]["players"][0]["personaname"])
				self.set_name("["+id+"] "+result["response"]["players"][0]["personaname"])
				profile_picture_url = result["response"]["players"][0]["avatarfull"]
				%infostep.value = 100
				request_info()
			else:
				push_error("NONEXISTANT STEAM ID: ", id)
		_: 
			push_error("UNREACHABLE STATE TO HANDLE: ", %infostep.value, "\n", self)
			return

func _on_http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != 0: 
		push_error("REQUEST RESULT != 0: ", result,"\n",_response_code, "\n",_headers)
	handle_result(body)


func _on_close_button_button_up():
	self.queue_free()
