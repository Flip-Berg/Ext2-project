class_name LifeManager
extends Node

signal life_lost(current_lifes:int)
signal dead

var current_lives: int
var max_lifes=3

func _ready() -> void:
	current_lives= max_lifes
	
func lose_life()->void :
	if current_lives<=0:
		return
	
	current_lives-=1
	life_lost.emit(current_lives)
	
	if current_lives<=0:
		dead.emit()
		# Para fechar o jogo:
		get_tree().quit()
	
		# Para reiniciar a cena atual:
		# get_tree().reload_current_scene()
