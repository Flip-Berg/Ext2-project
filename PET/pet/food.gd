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

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_home_position = position
	_original_z_index = z_index


func _process(_delta: float) -> void:
	if _dragging:
		global_position = get_global_mouse_position() + _grab_offset


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		if _draggable and not _dragging and _is_mouse_over():
			_start_drag()
	elif _dragging:
		_dragging = false
		z_index = _original_z_index
		dropped.emit()


func _is_mouse_over() -> bool:
	var size: Vector2 = (_shape.shape as RectangleShape2D).size
	var local_pos: Vector2 = _shape.to_local(get_global_mouse_position())
	return Rect2(-size / 2.0, size).has_point(local_pos)


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
