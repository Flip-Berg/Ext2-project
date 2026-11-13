class_name BasePop
extends TextureRect

signal expired
signal closed_by_player

@export var lifetime = 5.0


@export var popup_images: Array[Texture2D]

@onready var som_fecha: AudioStreamPlayer = $FechamentoSom

var lifetime_timer: Timer
var closed: bool=false

func _ready() -> void:
	_random_image()
	_time()
	
func _time() -> void:
	lifetime_timer = Timer.new()

	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)

	add_child(lifetime_timer)

	lifetime_timer.start()

func _random_image()->void:
	if popup_images.is_empty():
		return
	var tex: Texture2D = popup_images.pick_random()
	texture = tex
	size = tex.get_size()
	
func close() -> void:
	if closed:
		return
	
	closed=true
	closed_by_player.emit()
	
	if lifetime_timer!=null:
		lifetime_timer.stop()

	hide()
	som_fecha.play()
	await som_fecha.finished
	queue_free()
	
func _on_lifetime_timeout()-> void:
	if closed:
		return
	closed=true
	
	expired.emit()
	hide()
	som_fecha.play()
	await som_fecha.finished
	queue_free()
