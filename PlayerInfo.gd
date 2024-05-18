extends Control

const STEAM_URL := "https://api.steampowered.com/"
static var API_CALLS := PackedStringArray(["",
	"ISteamUser/ResolveVanityURL/v1/?",
	"ISteamUser/GetPlayerSummaries/v2/?",
	"ISteamUser/GetPlayerBans/v1/?",
	"ISteamUser/GetFriendList/v1/?",
	"TheoreticalBadgeCall",
	"IPlayerService/GetRecentlyPlayedGames/v1/?",
	"IPlayerService/GetOwnedGames/v1/?include_appinfo=true&include_played_free_games=true&",
	"ISteamUserStats/GetUserStatsForGame/v1/?appid=440&",
	"ISteamUserStats/GetPlayerAchievements/v1/?appid=440&",
])

# 0 uninitialized
# 1 resolve player name
# 2 base profile info
# 3 VAC bans
# 4 friend list
# 5 steam level / badges
# 6 recently played
# 7 owned games
# 8 tf2 stats
# 9 tf2 achievements (mainly completion times)
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
	#print(%infostep.value)
	match %infostep.value:
		1.0: %http.request(STEAM_URL + API_CALLS[1] + Key.get_formatted() + "&vanityurl=" + id)
		2.0: %http.request(STEAM_URL + API_CALLS[2] + Key.get_formatted() + "&steamids=" + id)
		3.0: %http.request(STEAM_URL + API_CALLS[3] + Key.get_formatted() + "&steamids=" + id)
		4.0: %http.request(STEAM_URL + API_CALLS[4] + Key.get_formatted() + "&steamid=" + id)
		5.0: 
			%infostep.value += 1 # badges are not useful at the moment so they are ignored
			request_info()
		6.0: %http.request(STEAM_URL + API_CALLS[6] + Key.get_formatted() + "&steamid=" + id)
		7.0: %http.request(STEAM_URL + API_CALLS[7] + Key.get_formatted() + "&steamid=" + id)
		8.0: %http.request(STEAM_URL + API_CALLS[8] + Key.get_formatted() + "&steamid=" + id)
		100.0: %http.request(profile_picture_url)
		255.0: 
			%infostep.visible = false
			if %suspicion.value != 0:
				%suspicion.show()
				$VBoxContainer/TFInfo/unsorted/Label.show()
			return
		_: 
			push_error("UNREACHABLE STATE REQUEST: ", %infostep.value, "\n", self)

func handle_result(result_string):
	if %infostep.value == 100:
		#print("TMP")
		var img = Image.new()
		var img_result = img.load_jpg_from_buffer(result_string)
		if img_result == 0:
			%PlayerIcon.set_texture(ImageTexture.create_from_image(img))
		else:
			push_warning("INVALID IMAGE RESULT: ", img_result)
		%infostep.value = 255
		request_info()
		return
	var str = result_string.get_string_from_utf8()
	var result: Dictionary = JSON.parse_string(str)
	match %infostep.value:
		1.0: # vanity URL
			if result["response"]["success"] == 1:
				id = result["response"]["steamid"]
			else:
				push_error("NONEXISTANT VANITY URL: ", id)
				return
		2.0: # base player info
			%PlayerSteamID.set_text(id)
			if len(result["response"]["players"]) != 0:
				%PlayerName.set_text(result["response"]["players"][0]["personaname"])
				self.set_name("["+id+"] "+result["response"]["players"][0]["personaname"])
				profile_picture_url = result["response"]["players"][0]["avatarfull"]
				if result["response"]["players"][0].has("timecreated"):
					%AccountCreationDate.set_text(Time.get_datetime_string_from_unix_time(result["response"]["players"][0]["timecreated"], true))
				else:
					%AccountCreationDate.hide()
			else:
				push_error("NONEXISTANT STEAM ID: ", id)
				return
		3.0: # Bans
			if len(result["players"]) != 0:
				%VACBanned.button_pressed = result["players"][0]["VACBanned"]
				%CommunityBanned.button_pressed = result["players"][0]["CommunityBanned"]
				%VACBanCounter.value = result["players"][0]["NumberOfVACBans"]
				%GameBanCounter.value = result["players"][0]["NumberOfGameBans"]
				if result["players"][0]["VACBanned"] or result["players"][0]["CommunityBanned"]:
					%DSLB.set_text(str(result["players"][0]["DaysSinceLastBan"])+ " Days since last ban")
					%suspicion.value += 1
				else:
					%NoBans.show()
					%DSLB.get_parent().hide()
			else:
				push_error("NONEXISTANT STEAM ID: ", id)
				return
		4.0: #Friends
			if result.has("friendslist"):
				for friend in result["friendslist"]["friends"]:
					var f = load("res://steam_display_friend.gd").new()
					%FriendContainer.add_child(f)
					f.initialize(friend["steamid"], friend["relationship"], friend["friend_since"])
				if len(result["friendslist"]["friends"]) == 0:
					%FriendContainer.get_child(0).set_text("no friends")
			else:
				%FriendContainer.get_child(0).set_text("Friends are not accessible")
		# 5.0: # currently not needed
		6.0: # recent games
			if result["response"].has("games"):
				%GameContainer.get_child(0).set_text("Recent games (" + str(result["response"]["total_count"]) + ")")
				for game in result["response"]["games"]:
					var l = Label.new()
					l.set_text(game["name"] + " [" + str(game["appid"]) + "]\nTotal: " + str(
						int(game["playtime_forever"]/60)) + "h" + str(int(game["playtime_forever"])%60)+"m\nLast2Weeks: " + str(
						int(game["playtime_2weeks"]/60)) + "h" + str(int(game["playtime_2weeks"])%60)+"m\n")
					%GameContainer.add_child(l)
			else:
				%GameContainer.get_child(0).set_text("no recent games available")
		7.0: # owned games
			if result["response"].has("games"):
				%OwnedGameContainer.get_child(0).set_text("Owned games (" + str(result["response"]["game_count"]) + ")")
				for game in result["response"]["games"]:
					var l = Label.new()
					l.set_text(game["name"] + " [" + str(game["appid"]) + "]\nTotal: " + str(
						int(game["playtime_forever"]/60)) + "h" + str(int(game["playtime_forever"])%60)+"m")
					%OwnedGameContainer.add_child(l)
			else:
				%OwnedGameContainer.get_child(0).set_text("no owned games available")
		8.0: # statistics
			if result.has("playerstats"):
				if result["playerstats"].has("stats"):
					resolve_playtimes(result["playerstats"])
			else:
				%TFInfo.hide()
			%infostep.value = 99
		_: # undefined / other
			push_error("UNREACHABLE STATE TO HANDLE: ", %infostep.value, "\n", self)
			return
	%infostep.value += 1
	request_info()

func _on_http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != 0: 
		push_error("REQUEST RESULT != 0: ", result,"\n",_response_code, "\n",_headers)
	handle_result(body)


func _on_close_button_button_up():
	self.queue_free()

func resolve_playtimes(data: Dictionary):
	var suspicion_conuter = -10
	for label in %PlaytimeValues.get_children():
		var identifier := String(label.name).capitalize() + ".accum.iPlayTime"
		if data["stats"].has(identifier):
			var playtime = int(data["stats"][identifier]["value"])
			label.set_text(str(playtime/3600) + "h" + str((playtime/60)%60) + "m" + str(playtime%60) + "s")
			if playtime/3600 > 50 and suspicion_conuter < 0:
				suspicion_conuter += 10
		else:
			label.set_text("__NOT_PLAYED__")
			suspicion_conuter += 1
	if suspicion_conuter > 5: # less then three classes ever played
		%suspicion.value += 1
	
	var i := 1
	var invalid := false
	var invalid_class := false
	for milestone in %Milestones.get_children():
		if i == 1:
			i = 0
			continue
		for level in milestone.get_children():
			#print(level.name, milestone.name, "TF_" + String(milestone.name).to_upper() + "_ACHIEVE_PROGRESS" + level.name)
			if data["achievements"].has("TF_" + String(milestone.name).to_upper() + "_ACHIEVE_PROGRESS" + level.name):
				if data["achievements"]["TF_" + String(milestone.name).to_upper() + "_ACHIEVE_PROGRESS" + level.name]["achieved"] == 1.0:
					level.set_deferred("button_pressed", true)
					if !data["achievements"].has("TF_" + String(milestone.name).to_upper() + "_ACHIEVE_PROGRESS" + str(int(String(level.name))-1)) and int(String(level.name))-1 > 1:
						invalid = true
					if %PlaytimeValues.get_node(NodePath(milestone.name)).get_text() == "__NOT_PLAYED__":
						invalid_class = true
	if invalid: # previous milestone not reached
		%suspicion.value += 1
	if invalid_class: # milestone reached without playing class
		%suspicion.value += 1
	
	for achievement in data["achievements"]:
		if achievement == "TF_HALLOWEEN_DOOMSDAY_MILESTONE":
			%halloweenMilestoneReached.set_deferred("button_pressed", true)
			%suspicion.value += 1
			%halloweenMilestoneReached.show()
