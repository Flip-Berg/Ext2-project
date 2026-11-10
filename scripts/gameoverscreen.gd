class_name GameOverScreen
extends CanvasLayer

const LOGIN_SCENE: String = "res://scenes/LoginScene.tscn"
const COR_DESTAQUE: Color = Color(1.0, 0.85, 0.2)
const COR_PLACEHOLDER: Color = Color(1.0, 1.0, 1.0, 0.5)
const TAMANHO_FONTE: int = 22

@onready var score_label: Label = %ScoreLabel
@onready var leaderboard_grid: GridContainer = %LeaderboardGrid
@onready var play_again_button: Button = %PlayAgainButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
	hide()
	play_again_button.pressed.connect(_on_play_again_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

## Mostra a tela com a pontuação da partida e o top 10.
## `new_entry` é a entrada devolvida por PlayerData.submit_score(), destacada no placar.
func show_results(score: int, new_entry: Dictionary) -> void:
	score_label.text = "Sua pontuação: %d pts" % score
	_fill_leaderboard(PlayerData.get_leaderboard_display(new_entry))
	show()
	play_again_button.grab_focus()

func _fill_leaderboard(rows: Array[Dictionary]) -> void:
	for child in leaderboard_grid.get_children():
		leaderboard_grid.remove_child(child)
		child.queue_free()

	for i in rows.size():
		var row: Dictionary = rows[i]
		var color: Color = Color.WHITE
		if row["highlight"]:
			color = COR_DESTAQUE
		elif row["placeholder"]:
			color = COR_PLACEHOLDER
		_add_cell("%d." % (i + 1), color, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_add_cell(row["name"], color, HORIZONTAL_ALIGNMENT_LEFT, true)
		_add_cell("%d pts" % row["score"], color, HORIZONTAL_ALIGNMENT_RIGHT, false)

func _add_cell(text: String, color: Color, alignment: HorizontalAlignment, expand: bool) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", TAMANHO_FONTE)
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_grid.add_child(label)

func _on_play_again_pressed() -> void:
	SceneTransition.change_scene_to_file(get_tree().current_scene.scene_file_path)

func _on_exit_pressed() -> void:
	SceneTransition.change_scene_to_file(LOGIN_SCENE)
