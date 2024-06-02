extends Node
class_name Tools

static var VALID_HEX_DIGITS := PackedStringArray(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "a", "B", "b", "C", "c", "D", "d", "E", "e", "F", "f"])

static func check_steam_id_format_validity(steam_id: String) -> bool:
	if len(steam_id) != 17: return false
	for c in steam_id:
		if !VALID_HEX_DIGITS.has(c): return false
	return true

static func extract_steam_ids_from_text(text: String) -> PackedStringArray:
	var parts := split_string_multiple_delimiters(text, ["/", "\\", "\"", ",", ";", "\n", "[", "]", "{", "}", " "])
	var valid_parts := PackedStringArray()
	
	for part in parts:
		if part.begins_with("U:1:"): part = id3_to_id64(part)
		if check_steam_id_format_validity(part):
			valid_parts.append(part)
	
	return valid_parts

static func split_string_multiple_delimiters(text: String, delimiters: PackedStringArray) -> PackedStringArray:
	var parts := PackedStringArray([text])
	
	for delimiter in delimiters:
		var subparts := PackedStringArray()
		for part in parts:
			subparts.append_array(part.split(delimiter))
		parts = subparts
	
	return parts

static func id64_to_id3(id64: String) -> String:
	return "[U:1:" + str(int(id64) - 76561197960265728) + "]"

static func id3_to_id64(id3: String) -> String:
	var i = int(id3.replace("U:1:", "").replace("[", "").replace("]", ""))
	
	return str(i + 76561197960265728)
