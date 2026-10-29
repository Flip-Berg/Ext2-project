class_name Food
extends Area2D

signal dropped

@export var drag_z_index: int = 100
@export var return_duration: float = 0.15

var _draggable: bool = false
var _dragging: bool = false
var _grab_offset: Vector2 = Vector2.ZERO
var _home_position: Vector2
var _original_z_index: int
var _return_tween: Tween


func _ready() -> void:
	input_pickable = true
	_home_position = position
	_original_z_index = z_index

func _process(_delta: float) -> void:
	if _dragging:
		global_position = get_global_mouse_position() + _grab_offset

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not _draggable or _dragging:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_start_drag()

func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_dragging = false
		z_index = _original_z_index
		dropped.emit()

func set_draggable(value: bool) -> void:
	_draggable = value
	if not value and _dragging:
		_dragging = false
		z_index = _original_z_index
		return_home()


func return_home() -> void:
	_kill_return_tween()
	_return_tween = create_tween()
	_return_tween.tween_property(self, "position", _home_position, return_duration)


func _start_drag() -> void:
	_kill_return_tween()
	_dragging = true
	_grab_offset = global_position - get_global_mouse_position()
	z_index = drag_z_index


func _kill_return_tween() -> void:
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
