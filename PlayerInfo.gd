extends Control

const STEAM_URL := "https://api.steampowered.com/"
static var API_CALLS := PackedStringArray(["",
	"ISteamUser/ResolveVanityURL/v1/?",
	"ISteamUser/GetPlayerSummaries/v2/?",
	"ISteamUser/GetPlayerBans/v1/?",
	"ISteamUser/GetFriendList/v1/?",
	"IPlayerService/GetBadges/v1/?",
	"IPlayerService/GetRecentlyPlayedGames/v1/?",
	"IPlayerService/GetOwnedGames/v1/?include_appinfo=true&include_played_free_games=true&",
	"ISteamUserStats/GetUserStatsForGame/v1/?appid=440&",
	"ISteamUserStats/GetPlayerAchievements/v1/?appid=440&",
])

var friends_to_load := 0

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
	match %infostep.value:
		1.0: %http.request(STEAM_URL + API_CALLS[1] + Key.get_formatted() + "&vanityurl=" + id)
		2.0: %http.request(STEAM_URL + API_CALLS[2] + Key.get_formatted() + "&steamids=" + id)
		3.0: %http.request(STEAM_URL + API_CALLS[3] + Key.get_formatted() + "&steamids=" + id)
		4.0: %http.request(STEAM_URL + API_CALLS[4] + Key.get_formatted() + "&steamid=" + id)
		5.0: %http.request(STEAM_URL + API_CALLS[5] + Key.get_formatted() + "&steamid=" + id)
		6.0: %http.request(STEAM_URL + API_CALLS[6] + Key.get_formatted() + "&steamid=" + id)
		7.0: %http.request(STEAM_URL + API_CALLS[7] + Key.get_formatted() + "&steamid=" + id)
		8.0: %http.request(STEAM_URL + API_CALLS[8] + Key.get_formatted() + "&steamid=" + id)
		9.0: %http.request(STEAM_URL + API_CALLS[9] + Key.get_formatted() + "&steamid=" + id)
		100.0: %http.request(profile_picture_url)
		255.0: 
			%infostep.visible = false
			check_suspicion()
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
	@warning_ignore("shadowed_global_identifier")
	var str = result_string.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(str) != 0:
		await get_tree().create_timer(0.3).timeout
		request_info()
		return
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
				if result["players"][0]["VACBanned"] or result["players"][0]["CommunityBanned"] or result["players"][0]["NumberOfGameBans"] != 0:
					%DSLB.show()
					%DSLB.set_text(str(result["players"][0]["DaysSinceLastBan"])+ " Days since last ban")
					%VAC_Ban.button_pressed = true
				else:
					%NoBans.show()
					%DSLB.get_parent().hide()
			else:
				push_error("NONEXISTANT STEAM ID: ", id)
				return
		4.0: #Friends
			if result.has("friendslist"):
				var i := 0
				for friend in result["friendslist"]["friends"]:
					var f = load("res://steam_display_friend.gd").new()
					%FriendContainer.add_child(f)
					@warning_ignore("integer_division")
					f.initialize(friend["steamid"], friend["relationship"], friend["friend_since"], i / 8)
					i += 1
					friends_to_load += 1
					f.FRIEND_COMPLETELY_LOADED.connect(friend_loaded)
				if len(result["friendslist"]["friends"]) == 0:
					%FriendContainer.get_child(0).set_text("no friends")
					%FriendContainer.get_child(1).hide()
				else:
					%FriendContainer.get_child(0).set_text("Friend list (loading)")
			else:
				%FriendContainer.get_child(0).set_text("Friends are not accessible")
				%FriendContainer.get_child(1).hide()
		5.0: # steam badges and level
			if result["response"].has("badges"):
				for badge in result["response"]["badges"]:
					if badge["badgeid"] == 1:
						if !badge.has("appid"):
							%PlayerSteamSteamBadge.set_deferred("button_pressed", true)
						elif badge["appid"] == 440:
							%PlayerSteamTfBadge.set_deferred("button_pressed", true)
			else:
				%PlayerSteamSteamBadge.get_parent().hide()
			if result["response"].has("player_level"):
				%PlayerSteamLevel.set_text("steam level " + str(result["response"]["player_level"]))
			else:
				%PlayerSteamLevel.hide()
		6.0: # recent games
			if result["response"].has("games"):
				%GameContainer.get_child(0).set_text("Recent games (" + str(result["response"]["total_count"]) + ")")
				for game in result["response"]["games"]:
					var l = Label.new()
					if game["appid"] == 440:
						%playtime.value = game["playtime_forever"]
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
					if game["appid"] == 440:
						%playtime.value = game["playtime_forever"]
					l.set_text(game["name"] + " [" + str(game["appid"]) + "]\nTotal: " + str(
						int(game["playtime_forever"]/60)) + "h" + str(int(game["playtime_forever"])%60)+"m")
					%OwnedGameContainer.add_child(l)
			else:
				%OwnedGameContainer.get_child(0).set_text("no owned games available")
		8.0: # statistics
			if result.has("playerstats"):
				if result["playerstats"].has("stats"):
					resolve_playtimes(result["playerstats"])
					resolve_milestones(result["playerstats"])
					resolve_various(result["playerstats"])
					resolve_var(result["playerstats"], %iNumberOfKills)
					resolve_var(result["playerstats"], %iDamageDealt)
					resolve_var(result["playerstats"], %iKillAssists)
					resolve_var(result["playerstats"], %iPointsScored)
					resolve_var(result["playerstats"], %iBuildingsDestroyed)
			else:
				%TFInfo.hide()
		9.0:
			if result.has("playerstats"): if result["playerstats"].has("achievements"):
				check_achievement_times(result["playerstats"]["achievements"])
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
			@warning_ignore("integer_division")
			label.set_text(str(playtime/3600) + "h" + str((playtime/60)%60) + "m" + str(playtime%60) + "s")
			if playtime > 50*3600 and suspicion_conuter < 0:
				suspicion_conuter += 10
			%totalPlaytime.value += int(playtime / 60)
		else:
			label.set_text("__NOT_PLAYED__")
			suspicion_conuter += 1
	if suspicion_conuter > 5: # less then three classes ever played
		%invalidPlaytimes.button_pressed = true
	
	for label in %MaxSessionPlaytime.get_children():
		var identifier := String(label.name).capitalize() + ".max.iPlayTime"
		if data["stats"].has(identifier):
			var playtime = int(data["stats"][identifier]["value"])
			@warning_ignore("integer_division")
			label.set_text(str(playtime/3600) + "h" + str((playtime/60)%60) + "m" + str(playtime%60) + "s")
		else:
			label.set_text("__NOT_SET__")
	
	if %playtime.value / 10 > %totalPlaytime.value: %tooLowActualPlaytime.button_pressed = true
	

func resolve_milestones(data: Dictionary):
	var i := 1
	var invalid := false
	var invalid_class := false
	for milestone in %Milestones.get_children():
		if i == 1:
			i = 0
			continue
		for level in milestone.get_children():
			if data["achievements"].has("TF_" + String(milestone.name).to_upper() + "_ACHIEVE_PROGRESS" + level.name):
				if data["achievements"]["TF_" + String(milestone.name).to_upper() + "_ACHIEVE_PROGRESS" + level.name]["achieved"] == 1.0:
					level.set_deferred("button_pressed", true)
					if !data["achievements"].has("TF_" + String(milestone.name).to_upper() + "_ACHIEVE_PROGRESS" + str(int(String(level.name))-1)) and int(String(level.name))-1 > 1:
						invalid = true
					if %PlaytimeValues.get_node(NodePath(milestone.name)).get_text() == "__NOT_PLAYED__":
						invalid_class = true
	if invalid: # previous milestone not reached
		%invalidMilestoneOrder.button_pressed = true
	if invalid_class: # milestone reached without playing class
		%invalidMilestoneObtained.button_pressed = true

func resolve_various(data: Dictionary):
	if data["stats"].has("Sniper.accum.iHeadshots"): %Sniper_X_iHeadshots/accum.set_text(str(data["stats"]["Sniper.accum.iHeadshots"]["value"]))
	if data["stats"].has("Sniper.max.iHeadshots"): %Sniper_X_iHeadshots/max.set_text(str(data["stats"]["Sniper.max.iHeadshots"]["value"]))
	if data["stats"].has("Sniper.accum.iHeadshots"): 
		%Sniper_X_iHeadshotRatio/accum.set_text(str(float(data["stats"]["Sniper.accum.iHeadshots"]["value"]) / float(data["stats"]["Sniper.accum.iNumberOfKills"]["value"])))
		if float(%Sniper_X_iHeadshotRatio/accum.get_text()) > 0.6: %highSniperHeadshotRate.button_pressed = true
	if data["stats"].has("Sniper.max.iHeadshots"): %Sniper_X_iHeadshotRatio/max.set_text(str(float(data["stats"]["Sniper.max.iHeadshots"]["value"]) / float(data["stats"]["Sniper.max.iNumberOfKills"]["value"])))
	
	if data["stats"].has("Spy.accum.iBackstabs"): %Spy_X_iBackstabs/accum.set_text(str(data["stats"]["Spy.accum.iBackstabs"]["value"]))
	if data["stats"].has("Spy.max.iBackstabs"): %Spy_X_iBackstabs/max.set_text(str(data["stats"]["Spy.max.iBackstabs"]["value"]))
	if data["stats"].has("Spy.accum.iBackstabs"): %Spy_X_iBackstabRatio/accum.set_text(str(float(data["stats"]["Spy.accum.iBackstabs"]["value"]) / float(data["stats"]["Spy.accum.iNumberOfKills"]["value"])))
	if data["stats"].has("Spy.max.iBackstabs"): %Spy_X_iBackstabRatio/max.set_text(str(float(data["stats"]["Spy.max.iBackstabs"]["value"]) / float(data["stats"]["Spy.max.iNumberOfKills"]["value"])))
	
	if data["stats"].has("Medic.accum.iHealthPointsHealed"): %Medic_X_iHealthPointsHealed/accum.set_text(str(data["stats"]["Medic.accum.iHealthPointsHealed"]["value"]))
	if data["stats"].has("Medic.max.iHealthPointsHealed"): %Medic_X_iHealthPointsHealed/max.set_text(str(data["stats"]["Medic.max.iHealthPointsHealed"]["value"]))
	if data["stats"].has("Engineer.accum.iNumTeleports"): %Engineer_X_iNumTeleports/accum.set_text(str(data["stats"]["Engineer.accum.iNumTeleports"]["value"]))
	if data["stats"].has("Engineer.max.iNumTeleports"): %Engineer_X_iNumTeleports/max.set_text(str(data["stats"]["Engineer.max.iNumTeleports"]["value"]))
	if data["stats"].has("Engineer.accum.iBuildingsBuilt"): %Engineer_X_iBuildingsBuilt/accum.set_text(str(data["stats"]["Engineer.accum.iBuildingsBuilt"]["value"]))
	if data["stats"].has("Engineer.max.iBuildingsBuilt"): %Engineer_X_iBuildingsBuilt/max.set_text(str(data["stats"]["Engineer.max.iBuildingsBuilt"]["value"]))
	
	for achievement in data["achievements"]:
		if achievement == "TF_HALLOWEEN_DOOMSDAY_MILESTONE":
			%halloweenMilestoneReached.set_deferred("button_pressed", true)
			%halloweenMilestoneReached.show()

func resolve_var(data: Dictionary, root: Node):
	var category := String(root.name)
	for count in root.get_children():
		var counting_method := String(count.name)
		for class_label in count.get_children():
			var c_name := String(class_label.name).capitalize()
			var data_name := c_name + "." + counting_method + "." + category
			if data["stats"].has(data_name):
				class_label.set_text(str(data["stats"][data_name]["value"]))
			else:
				class_label.set_text("")

func check_achievement_times(achievement_data: Array):
	var tf_halloween_count := 0
	for achievement in achievement_data:
		if achievement["apiname"] == "TF_HALLOWEEN_DOOMSDAY_MILESTONE" and achievement["achieved"] == 1:
			@warning_ignore("unused_variable")
			var time = Time.get_datetime_dict_from_unix_time(int(achievement["unlocktime"]))
			%halloweenMilestoneReached.text += "outside valid timeframe (" + Time.get_datetime_string_from_unix_time(int(achievement["unlocktime"])) + ")"
		if achievement["apiname"].contains("TF_HALLOWEEN_DOOMSDAY") and achievement["achieved"] == 1:
			tf_halloween_count += 1
	if tf_halloween_count > 4:
		%halloweenMilestoneReached.set_deferred("button_pressed", false)

func check_suspicion():
	%suspicion.set_suffix("of " + str(%suspicionConditions.get_child_count() - 1))
	for child in %suspicionConditions.get_children():
		if child.button_pressed:
			%suspicion.value += 1
	if %suspicion.value != 0:
		%suspicion.show()

func friend_loaded():
	friends_to_load -= 1
	
	if friends_to_load == 0:
		%FriendContainer.get_child(0).set_text("Friend list")
	else:
		%FriendContainer.get_child(0).set_text("Friend list (loading) [" + str(friends_to_load) + "]")


func _on_friend_list_search_text_changed(new_text):
	var ignore_ui := 2
	for child in %FriendContainer.get_children():
		if ignore_ui != 0:
			ignore_ui -= 1
			continue
		if child.get_child_count() == 3: continue # still loading
		child.visible = child.get_child(1).get_child(0).get_text().to_lower().contains(new_text.to_lower()) or new_text.to_lower().contains(child.get_child(1).get_child(0).get_text().to_lower())
		if new_text == "": child.visible = true
