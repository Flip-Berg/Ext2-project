extends Node

const SAVE_PATH: String = "user://player_data.json"

var player_name: String = "Dev_Anonimo"
var current_score: int = 0
var high_score: int = 0

func _ready() -> void:
	load_data()

func set_player_name(new_name: String) -> void:
	if new_name.strip_edges() != "":
		player_name = new_name.strip_edges()
	else:
		player_name = "Dev_Anonimo"
	save_data()

func update_score(score: int) -> void:
	current_score = score
	if current_score > high_score:
		high_score = current_score
		save_data()

func save_data() -> void:
	var data: Dictionary = {
		"player_name": player_name,
		"high_score": high_score
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.get_data()
			player_name = data.get("player_name", "Dev_Anonimo")
			high_score = data.get("high_score", 0)
