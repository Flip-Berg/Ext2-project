class_name PetController
extends Node2D

signal feeding_missed
signal fed

enum State {SLEEPING, AWAKE, STARVED}

@export_group("sprites")
@export var sprite_sleeping: Texture2D
@export var sprite_awake: Texture2D
@export var sprite_damage: Texture2D

@export_group("Timers")
@export var min_sleeping: float = 8.0
@export var max_sleeping: float = 20.0

@export var feed_window: float = 5.0
@export var damage_time: float = 3.0

var state: State = State.SLEEPING

@onready var wake_timer: Timer = $WakeTimer
@onready var feed_timer: Timer = $FeedTimer
@onready var mail_bar: Mail = $Mail
@onready var letter: Letter = mail_bar.letter
@onready var damage_timer: Timer = $DamageTimer
@onready var pet: Sprite2D = $PetSprite
@onready var feeding_zone: Area2D = $FeedingZone
@onready var som_dormiu: AudioStreamPlayer = $DormiuSom
@onready var som_acordou: AudioStreamPlayer = $AcordouSom

func _ready() -> void:
	for timer in [wake_timer, feed_timer, damage_timer]:
		timer.one_shot = true
 
	wake_timer.timeout.connect(_on_wake_timer_timeout)
	feed_timer.timeout.connect(_on_feeding_timer_timeout)
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	letter.dropped.connect(_on_letter_dropped)
	fed.connect(mail_bar._show_next)
 
	_enter_sleeping()

func stop() -> void:
	wake_timer.stop()
	feed_timer.stop()
	damage_timer.stop()
	letter.set_draggable(false)

func _enter_awake() -> void:
	state = State.AWAKE
	pet.texture = sprite_awake
	letter.set_draggable(true)
	feed_timer.start(feed_window)
	
func _enter_sleeping() -> void:
	state = State.SLEEPING
	pet.texture = sprite_sleeping
	letter.set_draggable(false)
	wake_timer.start(randf_range(min_sleeping, max_sleeping))

func _enter_starved() -> void:
	state = State.STARVED
	pet.texture = sprite_damage
	letter.set_draggable(false)
	damage_timer.start(damage_time)
	feeding_missed.emit()
	
func _on_letter_dropped() -> void:
	if state == State.AWAKE and feeding_zone.overlaps_area(letter):
		feed_timer.stop()
		letter.return_home()
		fed.emit()
		som_dormiu.play()
		_enter_sleeping()
	else:
		letter.return_home()

func _on_wake_timer_timeout() -> void:
	som_acordou.play()
	_enter_awake()

func _on_feeding_timer_timeout() -> void:
	_enter_starved()

func _on_damage_timer_timeout() -> void:
	_enter_sleeping()
