extends CanvasLayer

@export var static_popup: PackedScene
@export var moving_popup: PackedScene
@export var multiplier_popup: PackedScene

@export var spawn_offset: float = 100.0
@export var popup_dimensions: Vector2 = Vector2(620, 241)

@export var initial_max_time: float = 15.0
@export var initial_min_time: float = 5.0

@export var max_min_time: float = 5.0
@export var regression: float = 0.03

var game: float = 0.0

@onready var life_manager: LifeManager = $"../LifeManager"
@onready var timer: Timer = $SpawnTimer


func _ready() -> void:
	timer.timeout.connect(_spawn_time)
	_reset_timer()


func _process(delta: float) -> void:
	game += delta


func _reset_timer() -> void:
	var reduction := game * regression

	var new_max := maxf(initial_max_time - reduction, max_min_time)
	var new_min := maxf(max_min_time, initial_min_time - reduction)

	timer.wait_time = randf_range(new_min, new_max)
	timer.start()


func _spawn_time() -> void:
	_spawn_random()
	_reset_timer()


func _spawn_random() -> void:
	var pool := [
		static_popup,
		moving_popup,
		multiplier_popup
	]

	var choice: PackedScene = pool.pick_random()

	if choice != null:
		_spawn_popup(choice)


# Área onde o canto superior esquerdo do popup pode ficar:
# centro da tela ± spawn_offset, limitado às bordas da tela.
func _get_spawn_rect(popup_size: Vector2) -> Rect2:
	var screen := get_viewport().get_visible_rect().size

	var centered_pos := (screen - popup_size) / 2.0

	var screen_max := Vector2(
		maxf(0.0, screen.x - popup_size.x),
		maxf(0.0, screen.y - popup_size.y)
	)

	var min_pos := Vector2(
		clampf(centered_pos.x - spawn_offset, 0.0, screen_max.x),
		clampf(centered_pos.y - spawn_offset, 0.0, screen_max.y)
	)

	var max_pos := Vector2(
		clampf(centered_pos.x + spawn_offset, 0.0, screen_max.x),
		clampf(centered_pos.y + spawn_offset, 0.0, screen_max.y)
	)

	return Rect2(min_pos, max_pos - min_pos)


func _spawn_popup(
	scene: PackedScene,
	custom_pos: Vector2 = Vector2(-1, -1)
) -> BasePop:

	var popup: BasePop = scene.instantiate()
	add_child(popup)

	popup.set_anchors_preset(Control.PRESET_TOP_LEFT)
	popup.custom_minimum_size = popup_dimensions
	popup.size = popup_dimensions

	# Usa o tamanho real do popup depois de aplicado
	var area := _get_spawn_rect(popup.size * popup.scale)

	var target_pos: Vector2

	if custom_pos == Vector2(-1, -1):
		target_pos = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
	else:
		target_pos = custom_pos

	popup.position = Vector2(
		clampf(target_pos.x, area.position.x, area.end.x),
		clampf(target_pos.y, area.position.y, area.end.y)
	)

	popup.expired.connect(_on_popup_expired)

	if popup.has_signal("request"):
		if not popup.is_connected("request", _on_multiplier_triggered):
			popup.connect("request", _on_multiplier_triggered)

	return popup


func _on_popup_expired() -> void:
	life_manager.lose_life()


func _on_multiplier_triggered(pos: Vector2) -> void:
	for i in range(2):
		var offset := Vector2(
			randf_range(-20.0, 20.0),
			randf_range(-20.0, 20.0)
		)

		_spawn_popup(static_popup, pos + offset)
