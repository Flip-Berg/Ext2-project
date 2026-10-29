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
@export var min_sleeping= 8.0
@export var max_sleeping= 20.0
# Penis
@export var penis= 5.0
@export var damage_time=3.0

var state: State= State.SLEEPING

@onready var wake_timer: Timer = $WakeTimer
@onready var feed_timer: Timer = $FeedTimer
@onready var food: Food = $Food
@onready var damage_timer: Timer = $DamageTimer
@onready var pet: Sprite2D = $PetSprite
@onready var feeding_zone:  = $FeedingZone

func _ready() -> void:
	for timer in [wake_timer, feed_timer, damage_timer]:
		timer.one_shot = true
 
	wake_timer.timeout.connect(_on_wake_timer_timeout)
	feed_timer.timeout.connect(_on_feeding_timer_timeout)
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	food.dropped.connect(_on_food_dropped)
 
	_enter_sleeping()
 
 
func stop() -> void:
	wake_timer.stop()
	feed_timer.stop()
	damage_timer.stop()
	food.set_draggable(false)

func _enter_awake() -> void:
	state= State.AWAKE
	pet.texture= sprite_awake
	food.set_draggable(true)
	feed_timer.start(penis)
	
func _enter_sleeping() -> void:
	state= State.SLEEPING
	pet.texture= sprite_sleeping
	food.set_draggable(false)
	wake_timer.start(randf_range(min_sleeping, max_sleeping))

func _enter_starved() -> void:
	state= State.STARVED
	pet.texture= sprite_damage
	food.set_draggable(false)
	damage_timer.start(damage_time)
	feeding_missed.emit()
	
func _on_food_dropped() ->void:
	if state == State.AWAKE and feeding_zone.overlaps_area(food):
		feed_timer.stop()
		food.return_home()
		fed.emit()
		_enter_sleeping()
	else:
		food.return_home()
		

func _on_wake_timer_timeout() -> void:
	_enter_awake()
 
 
func _on_feeding_timer_timeout() -> void:
	_enter_starved()
 
 
func _on_damage_timer_timeout() -> void:
	_enter_sleeping()
	
