class_name BasePop
extends TextureRect

signal expired
signal closed_by_player

@export var lifetime = 5.0

@export var popup_images: Array[Texture2D]
@export var popup_grid: Array[Texture2D]

@onready var random_image: TextureRect= $RandomImage
@onready var random_grid: TextureRect= $RandomGrid
@onready var som_fecha: AudioStreamPlayer = $FechamentoSom

var lifetime_timer: Timer
var closed: bool=false

func _ready() -> void:
	_random_grid()
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
	random_image.texture= popup_images.pick_random()

func _random_grid()->void:
	if popup_grid.is_empty():
		return
	random_grid.texture= popup_grid.pick_random()
	
func close() -> void:
	if closed:
		return
	
	closed=true
	closed_by_player.emit()
	
	if lifetime_timer!=null:
		lifetime_timer.stop()
	# Esconde o pop-up (e para de receber cliques) e só libera o nó depois
	# que o som terminar; o player é filho do pop-up e seria cortado.
	hide()
	som_fecha.play()
	await som_fecha.finished
	queue_free()
	
func _on_lifetime_timeout()-> void:
	if closed:
		return
	closed=true
	
	expired.emit()
	
	queue_free()
