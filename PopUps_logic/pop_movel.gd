extends BasePop

@export var speed: float = 100.0

var direction: Vector2


func _ready() -> void:
	super()
	var angle = randf_range(0.0, TAU)

	direction = Vector2.RIGHT.rotated(angle)


func _process(delta: float) -> void:
	global_position += speed * direction * delta

	screen_bounce()


func screen_bounce() -> void:
	var screen = get_viewport_rect().size
	var popup = size

	if (
		(global_position.x < 0 and direction.x < 0)
		or
		(global_position.x + popup.x > screen.x and direction.x > 0)
	):
		direction.x *= -1

	if (
		(global_position.y < 0 and direction.y < 0)
		or
		(global_position.y + popup.y > screen.y and direction.y > 0)
	):
		direction.y *= -1
