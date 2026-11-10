extends CanvasLayer

const HEART_TEXTURE: Texture2D = preload("res://PopUps_logic/sprites/coracao.png")
const HEART_SIZE:= Vector2(48,48)
@onready var lives_container: HBoxContainer = $LivesContainer 
# LivesLabel ainda não existe no GameScene; fica null até ser criado (tela de game over).
@onready var lives_label: Label = get_node_or_null("LivesLabel")
@onready var life_manager: LifeManager = $"../LifeManager"


func _ready() -> void:
	life_manager.life_lost.connect(_on_life_lost)
	#life_manager.dead.connect(_on_dead)

	_update_lives(life_manager.current_lives)


func _on_life_lost(current_lives: int) -> void:
	_update_lives(current_lives)


func _update_lives(current_lives: int) -> void:
	for child in lives_container.get_children():
		lives_container.remove_child(child)
		child.queue_free()
	
	for i in range(current_lives):
		var heart:= TextureRect.new()
		heart.texture= HEART_TEXTURE
		heart.custom_minimum_size= HEART_SIZE
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lives_container.add_child(heart)
		
		
#func _on_dead() -> void:
#lives_label.text = "GAME OVER"
