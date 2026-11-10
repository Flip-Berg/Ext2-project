extends Node

const SAVE_PATH: String = "user://player_data.json"
const LEADERBOARD_SIZE: int = 10

# Preenchem as vagas vazias do placar (de 40 a 10 pts). Nunca são salvas.
const PLACEHOLDER_ENTRIES: Array = [
	{"name": "root", "score": 40},
	{"name": "admin", "score": 37},
	{"name": "DBA_do_mal", "score": 33},
	{"name": "sudo", "score": 30},
	{"name": "Marcelo_do_RH", "score": 27},
	{"name": "estagiario", "score": 23},
	{"name": "localhost", "score": 20},
	{"name": "SELECT_estrela", "score": 17},
	{"name": "null", "score": 13},
	{"name": "Dev_Anonimo", "score": 10},
]

signal score_changed(score: int)

var player_name: String = "Dev_Anonimo"
var current_score: int = 0
var high_score: int = 0
# Só entradas reais, da maior para a menor pontuação, no máximo LEADERBOARD_SIZE.
var leaderboard: Array[Dictionary] = []

func _ready() -> void:
	load_data()

func set_player_name(new_name: String) -> void:
	if new_name.strip_edges() != "":
		player_name = new_name.strip_edges()
	else:
		player_name = "Dev_Anonimo"
	save_data()

## Zera a pontuação no começo de cada partida.
func start_run() -> void:
	current_score = 0
	score_changed.emit(current_score)

func add_points(points: int) -> void:
	current_score += points
	score_changed.emit(current_score)

## Salva a pontuação da partida no placar e devolve a entrada criada
## (ou um dicionário vazio se ela não entrou no top 10).
func submit_score() -> Dictionary:
	high_score = maxi(high_score, current_score)
	var entry: Dictionary = {"name": player_name, "score": current_score}

	# Empates ficam abaixo de quem chegou primeiro.
	var index: int = leaderboard.size()
	for i in leaderboard.size():
		if current_score > int(leaderboard[i]["score"]):
			index = i
			break
	leaderboard.insert(index, entry)
	if leaderboard.size() > LEADERBOARD_SIZE:
		leaderboard.resize(LEADERBOARD_SIZE)

	save_data()
	return entry if index < LEADERBOARD_SIZE else {}

## As 10 linhas para mostrar: entradas reais + placeholders nas vagas que faltam.
## Cada linha tem "name", "score", "placeholder" e "highlight" (a entrada `highlight`).
func get_leaderboard_display(highlight: Dictionary = {}) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry in leaderboard:
		rows.append({
			"name": entry["name"],
			"score": int(entry["score"]),
			"placeholder": false,
			"highlight": is_same(entry, highlight),
		})
	for i in LEADERBOARD_SIZE - rows.size():
		var fake: Dictionary = PLACEHOLDER_ENTRIES[i]
		rows.append({"name": fake["name"], "score": fake["score"], "placeholder": true, "highlight": false})

	# Em empate, a entrada real fica acima do placeholder.
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		return not a["placeholder"] and b["placeholder"])
	return rows

func save_data() -> void:
	var data: Dictionary = {
		"player_name": player_name,
		"high_score": high_score,
		"leaderboard": leaderboard,
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
		if parse_result == OK and json.get_data() is Dictionary:
			var data: Dictionary = json.get_data()
			player_name = data.get("player_name", "Dev_Anonimo")
			high_score = int(data.get("high_score", 0))

			leaderboard.clear()
			for entry in data.get("leaderboard", []):
				if entry is Dictionary and entry.has("name") and entry.has("score"):
					leaderboard.append({"name": str(entry["name"]), "score": int(entry["score"])})

			# Saves antigos só tinham o recorde: vira a primeira entrada do placar.
			if leaderboard.is_empty() and high_score > 0:
				leaderboard.append({"name": player_name, "score": high_score})
