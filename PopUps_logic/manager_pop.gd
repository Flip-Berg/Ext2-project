extends CanvasLayer

@export var static_popup: PackedScene
@export var moving_popup: PackedScene
@export var multiplier_popup: PackedScene

@onready var life_manager: LifeManager= $"../LifeManager"
@onready var timer: Timer = $SpawnTimer

var initial_max_time=15
var initial_min_time=5

var max_min_time= 5
var regression= 0.03
var game_time: float=0.0

var game: float = 0.0


func _process(delta: float) -> void:
	game += delta
	
func _ready() -> void:
	timer.timeout.connect(_spawn_time)
	_reset_timer()


func _reset_timer() -> void:
	var reduction = game*regression
	
	var new_max= max(
		initial_max_time-reduction,
		max_min_time
	)
	var new_min = max(
			max_min_time,
			initial_min_time - reduction
		)
	
	timer.wait_time= randf_range(new_min, new_max)
	timer.start()
	
func _spawn_time() -> void:
	_spawn_random()


func _spawn_random() -> void:
	var pool = [
		static_popup,
		moving_popup,
		multiplier_popup
	]

	var choice: PackedScene = pool.pick_random()
	if choice:
		_spawn_popup(choice)


func _spawn_popup(
	scene: PackedScene,
	custom_pos: Vector2 = Vector2(-1, -1)
) -> BasePop:

	var popup: BasePop = scene.instantiate()
	add_child(popup)
	popup.expired.connect(_on_popup_expired)
	popup.reset_size()

	var viewport_rect = get_viewport().get_visible_rect()
	var screen_size = viewport_rect.size

	var popup_size = popup.get_combined_minimum_size()
	if popup_size == Vector2.ZERO:
		popup_size = popup.size

	var min_x = 0.0
	var min_y = 0.0
	var max_x = max(0.0, screen_size.x - popup_size.x)
	var max_y = max(0.0, screen_size.y - popup_size.y)

	var target_pos: Vector2

	if custom_pos == Vector2(-1, -1):
		target_pos = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
	else:
		target_pos = Vector2(
			clamp(custom_pos.x, min_x, max_x),
			clamp(custom_pos.y, min_y, max_y)
		)

	popup.global_position = target_pos

	if popup.has_signal("request") and not popup.request.is_connected(_on_multiplier_triggered):
		popup.request.connect(_on_multiplier_triggered)

	return popup

func _on_popup_expired()-> void:
	life_manager.lose_life()

func _on_multiplier_triggered(pos: Vector2) -> void:
	for i in range(2):
		var offset = Vector2(
			randf_range(-20.0, 20.0),
			randf_range(-20.0, 20.0)
		)	
		_spawn_popup(static_popup, pos + offset)
