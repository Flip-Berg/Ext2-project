class_name Mail
extends Node2D

@export var emails: Array[String] = []
@export var fade_time: float = 0.12

@onready var letter: Letter = $Letter
@onready var text: Label = $Email  

var index: int = -1
var tween: Tween

func _ready() -> void:
	_show_next()

func _show_next(animate: bool = true) -> void:
	if emails.is_empty():
		_apply("")
		return
		
	index = _pick_index()
	var selected_text: String = emails[index]
	
	_kill_tween()
	if not animate or fade_time <= 0.0:
		text.modulate.a = 1.0
		_apply(selected_text)
		return
	
	# some -> troca o texto -> reaparece
	tween = create_tween()
	tween.tween_property(text, "modulate:a", 0.0, fade_time)
	tween.tween_callback(_apply.bind(selected_text))
	tween.tween_property(text, "modulate:a", 1.0, fade_time)

func _pick_index() -> int:
	if emails.size() <= 1:
		return 0
	var i := index
	while i == index:
		i = randi() % emails.size()
	return i

func _apply(content: String) -> void:
	if content.is_empty():
		text.text = "Nenhum texto"
		return
	text.text = content.replace("\n", " ")

func _kill_tween() -> void:
	if tween and tween.is_valid():
		tween.kill()
