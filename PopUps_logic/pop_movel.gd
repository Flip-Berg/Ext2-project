extends BasePop

@export var speed: float = 100.0
@export var bounce_offset: float = 100.0 # distância do centro até onde ele rebate

var direction: Vector2


func _ready() -> void:
	super()

	var angle := randf_range(0.0, TAU)
	direction = Vector2.RIGHT.rotated(angle)


func _process(delta: float) -> void:
	position += speed * direction * delta
	screen_bounce()


func screen_bounce() -> void:
	var screen := get_viewport_rect().size
	var popup_size := size * scale # considera scale caso a cena use

	# Posição (canto superior esquerdo) que deixa o popup centralizado
	var centered_pos := (screen - popup_size) / 2.0

	# Máximo possível para o popup não sair da tela
	var screen_max := Vector2(
		maxf(0.0, screen.x - popup_size.x),
		maxf(0.0, screen.y - popup_size.y)
	)

	# Área permitida: centro ± offset, sempre dentro da tela
	var min_x := clampf(centered_pos.x - bounce_offset, 0.0, screen_max.x)
	var max_x := clampf(centered_pos.x + bounce_offset, 0.0, screen_max.x)
	var min_y := clampf(centered_pos.y - bounce_offset, 0.0, screen_max.y)
	var max_y := clampf(centered_pos.y + bounce_offset, 0.0, screen_max.y)

	if position.x < min_x:
		position.x = min_x
		direction.x = absf(direction.x)
	elif position.x > max_x:
		position.x = max_x
		direction.x = -absf(direction.x)

	if position.y < min_y:
		position.y = min_y
		direction.y = absf(direction.y)
	elif position.y > max_y:
		position.y = max_y
		direction.y = -absf(direction.y)
