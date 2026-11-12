
class_name LifeManager
extends Node

signal life_lost(current_lives: int)
signal life_gained(current_lives: int)
signal dead
## Vidas voltaram ao valor inicial (fim do tutorial).
signal lives_reset(current_lives: int)

# Comeca com 3, mas pode chegar a 7 vidas
@export var initial_lives: int = 3
@export var max_lifes: int = 7

var current_lives: int = 0
## Enquanto true (tutorial), errar não custa vida.
var invulnerable: bool = false


func _ready() -> void:
	current_lives = mini(initial_lives, max_lifes)


func lose_life() -> void:
	if current_lives <= 0 or invulnerable:
		return

	current_lives -= 1
	life_lost.emit(current_lives)

	if current_lives <= 0:
		dead.emit()


## Volta para as vidas iniciais.
func reset_lives() -> void:
	current_lives = mini(initial_lives, max_lifes)
	lives_reset.emit(current_lives)


# Recupera uma vida, respeitando o limite
func gain_life() -> bool:
	if current_lives >= max_lifes:
		return false

	current_lives += 1
	life_gained.emit(current_lives)
	return true
