extends Node2D

@onready var life_manager: LifeManager = $LifeManager
@onready var pet: PetController = $Pet
@onready var manager_pop = $ManagerPop
@onready var minigame = $Node2D
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var director: DifficultyDirector = $DifficultyDirector
@onready var som_dano: AudioStreamPlayer = $DanoSom


func _ready() -> void:
	PlayerData.start_run()
	manager_pop.director = director
	minigame.director = director

	pet.feeding_missed.connect(_on_pet_feeding_missed)
	# Só o SQL dá pontos (ver SqlQuestion.points()); pop-ups e pet só tiram vidas.
	minigame.resposta_correta.connect(PlayerData.add_points)
	minigame.tempo_esgotado.connect(_on_sql_tempo_esgotado)
	life_manager.dead.connect(_on_dead)

	# O som da última vida perdida toca até o fim mesmo com o jogo pausado.
	som_dano.process_mode = Node.PROCESS_MODE_ALWAYS
	manager_pop.som_dano.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_pet_feeding_missed() -> void:
	som_dano.play()
	life_manager.lose_life()


func _on_sql_tempo_esgotado() -> void:
	som_dano.play()
	life_manager.lose_life()


func _on_dead() -> void:
	# Pausar congela pop-ups, pet, minigame e música; a tela de game over
	# (process_mode = Always) continua funcionando.
	get_tree().paused = true
	var entry: Dictionary = PlayerData.submit_score()
	game_over_screen.show_results(PlayerData.current_score, entry)
