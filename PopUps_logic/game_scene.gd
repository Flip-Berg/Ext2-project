extends Node2D

# Pontos por ação. Provisório: ajuste aqui quando as regras de pontuação forem definidas.
const PONTOS_POPUP_FECHADO: int = 1
const PONTOS_PET_ALIMENTADO: int = 1
const PONTOS_SQL_CORRETA: int = 1

@onready var life_manager: LifeManager = $LifeManager
@onready var pet: PetController = $Pet
@onready var manager_pop = $ManagerPop
@onready var minigame = $Node2D
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var som_dano: AudioStreamPlayer = $DanoSom


func _ready() -> void:
	PlayerData.start_run()

	pet.feeding_missed.connect(_on_pet_feeding_missed)
	pet.fed.connect(PlayerData.add_points.bind(PONTOS_PET_ALIMENTADO))
	manager_pop.popup_closed.connect(PlayerData.add_points.bind(PONTOS_POPUP_FECHADO))
	minigame.resposta_correta.connect(PlayerData.add_points.bind(PONTOS_SQL_CORRETA))
	life_manager.dead.connect(_on_dead)

	# O som da última vida perdida toca até o fim mesmo com o jogo pausado.
	som_dano.process_mode = Node.PROCESS_MODE_ALWAYS
	manager_pop.som_dano.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_pet_feeding_missed() -> void:
	som_dano.play()
	life_manager.lose_life()


func _on_dead() -> void:
	# Pausar congela pop-ups, pet, minigame e música; a tela de game over
	# (process_mode = Always) continua funcionando.
	get_tree().paused = true
	var entry: Dictionary = PlayerData.submit_score()
	game_over_screen.show_results(PlayerData.current_score, entry)
