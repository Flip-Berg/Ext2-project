extends Node2D

@onready var life_manager = $LifeManager
@onready var pet: PetController = $Pet
 
 
func _ready() -> void:
	pet.feeding_missed.connect(_on_pet_feeding_missed)
 
 
func _on_pet_feeding_missed() -> void:
	life_manager.lose_life()
