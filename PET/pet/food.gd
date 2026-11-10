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


# Usa _input (e não _input_event) porque o Panel do minigame SQL fica por cima
# da carta e bloquearia o picking de física. Em troca, precisamos ignorar
# manualmente os cliques que caem em cima de um pop-up.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		if _draggable and not _dragging and _is_event_over(event) and not _is_covered_by_popup():
			_start_drag()
			get_viewport().set_input_as_handled()
	elif _dragging:
		_dragging = false
		z_index = _original_z_index
		dropped.emit()
		get_viewport().set_input_as_handled()


func _is_event_over(event: InputEvent) -> bool:
	var local_pos: Vector2 = _shape.make_input_local(event).position
	return _shape.shape.get_rect().has_point(local_pos)


# Um pop-up aberto por cima da carta deve receber o clique, não a carta.
func _is_covered_by_popup() -> bool:
	var node: Node = get_viewport().gui_get_hovered_control()
	while node != null:
		if node is BasePop:
			return true
		node = node.get_parent()
	return false


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
