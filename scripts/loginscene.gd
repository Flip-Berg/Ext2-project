extends Control

@onready var name_input: LineEdit = $Panel/LineEdit
@onready var login_button: Button = $Panel/Button
@onready var high_score_label: Label = $Panel/HighScoreLabel

func _ready() -> void:
	# Carrega o nome e recorde salvos anteriormente
	name_input.add_theme_constant_override("minimum_character_width", 15)
	name_input.text = PlayerData.player_name
	high_score_label.text = "Recorde Atual: " + str(PlayerData.high_score) + " pts"
	
	# Conecta sinais
	login_button.pressed.connect(_on_login_pressed)
	name_input.text_submitted.connect(_on_text_submitted)
	
	name_input.grab_focus() # Foca automaticamente no campo de texto

func _on_text_submitted(_new_text: String) -> void:
	_on_login_pressed()

func _on_login_pressed() -> void:
	PlayerData.set_player_name(name_input.text)
	
	SceneTransition.change_scene_to_file("res://PopUps_logic/GameScene.tscn",0.5)
