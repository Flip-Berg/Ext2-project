extends Control

const GAME_SCENE: String = "res://PopUps_logic/GameScene.tscn"

@onready var name_input: LineEdit = $Janela/LineEdit
@onready var high_score_label: Label = $Janela/HighScoreLabel
## As carinhas do Login.png, na ordem: fácil, médio, difícil.
@onready var difficulty_buttons: Array[Button] = [$Janela/FacilButton, $Janela/MedioButton, $Janela/DificilButton]

func _ready() -> void:
	# Carrega o nome e recorde salvos anteriormente
	name_input.text = PlayerData.player_name
	high_score_label.text = "Recorde Atual: %d pts" % PlayerData.high_score

	# Cada carinha começa o jogo numa dificuldade; Enter no nome começa no fácil.
	for i in difficulty_buttons.size():
		difficulty_buttons[i].pressed.connect(_start.bind(i))
	name_input.text_submitted.connect(func(_text: String) -> void: _start(0))

	name_input.grab_focus() # Foca automaticamente no campo de texto

func _start(difficulty: int) -> void:
	PlayerData.set_player_name(name_input.text)
	PlayerData.starting_difficulty = difficulty
	SceneTransition.change_scene_to_file(GAME_SCENE, 0.5)
