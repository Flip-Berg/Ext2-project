extends Node2D

@onready var life_manager = $LifeManager
@onready var pet: PetController = $Pet
@onready var som_dano: AudioStreamPlayer = $DanoSom 
 
func _ready() -> void:
	pet.feeding_missed.connect(_on_pet_feeding_missed)
 
 
func _on_pet_feeding_missed() -> void:
	som_dano.play()
	life_manager.lose_life()
