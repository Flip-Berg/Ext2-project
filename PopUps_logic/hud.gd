extends CanvasLayer

@onready var lives_label: Label = $LivesLabel
@onready var life_manager: LifeManager = $"../LifeManager"


func _ready() -> void:
	life_manager.life_lost.connect(_on_life_lost)
	life_manager.dead.connect(_on_dead)

	_update_lives(life_manager.current_lives)


func _on_life_lost(current_lives: int) -> void:
	_update_lives(current_lives)


func _update_lives(current_lives: int) -> void:
	lives_label.text = ""

	for i in range(current_lives):
		lives_label.text += "♥ "


func _on_dead() -> void:
	lives_label.text = "GAME OVER"
