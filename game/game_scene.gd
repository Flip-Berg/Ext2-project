
extends Node2D

const QUERIES_POR_TENTATIVA: int = 5

const RECOVERY_SCENE: PackedScene = preload(
	"res://recovery_challenge.tscn"
)

@onready var life_manager: LifeManager = $LifeManager
@onready var pet: PetController = $Pet
@onready var manager_pop = $ManagerPop
@onready var minigame = $Node2D
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var director: DifficultyDirector = $DifficultyDirector
@onready var som_dano: AudioStreamPlayer = $DanoSom
@onready var hud = $HUD
@onready var tutorial: Tutorial = $Tutorial

var consultas_corretas: int = 0
var tentativas_acumuladas: int = 0
var desafio_em_andamento: bool = false

var recovery_challenge: Control

## Fim de um desafio 6-7 (depois de o jogo voltar a rodar). O tutorial espera por ele.
signal desafio_6_7_terminou(sucesso: bool)


# ==========================================
# INICIALIZACAO
# ==========================================

func _ready() -> void:
	PlayerData.start_run()

	manager_pop.director = director
	minigame.director = director

	consultas_corretas = 0
	tentativas_acumuladas = 0

	pet.feeding_missed.connect(_on_pet_feeding_missed)

	# Só o SQL dá pontos (ver SqlQuestion.points()); pop-ups e pet só tiram vidas.
	# No tutorial as respostas não valem pontos nem contam para o 6-7.
	minigame.resposta_correta.connect(_on_resposta_correta)
	minigame.tempo_esgotado.connect(_on_sql_tempo_esgotado)

	life_manager.dead.connect(_on_dead)

	som_dano.process_mode = Node.PROCESS_MODE_ALWAYS
	manager_pop.som_dano.process_mode = Node.PROCESS_MODE_ALWAYS

	hud.recovery_requested.connect(_on_recovery_requested)

	_preparar_desafio()

	hud.atualizar_tentativas(tentativas_acumuladas)

	if PlayerData.needs_tutorial():
		_preparar_tutorial()
	# Sem tutorial, o minigame começa sozinho (automatico já vem ligado).


# ==========================================
# TUTORIAL
# ==========================================

## Tutorial: sem tempo, sem pop-ups sozinhos, pet dormindo e sem perder vidas.
## O minigame espera as perguntas do tutorial em vez de sortear.
func _preparar_tutorial() -> void:
	minigame.automatico = false
	minigame.sem_tempo = true
	manager_pop.set_active(false)
	pet.stop()
	life_manager.invulnerable = true
	tutorial.finished.connect(_comecar_partida)
	tutorial.start.call_deferred(minigame, manager_pop, pet, self)


## Fim do tutorial: começa a partida valendo, do zero.
func _comecar_partida() -> void:
	life_manager.invulnerable = false
	minigame.sem_tempo = false
	minigame.automatico = true
	minigame.esconder_dica()
	manager_pop.set_active(true)
	pet.resume()
	director.elapsed = 0.0
	PlayerData.start_run()
	# A vida ganha no treino do 6-7 não vale para a partida.
	life_manager.reset_lives()
	consultas_corretas = 0
	tentativas_acumuladas = 0
	hud.atualizar_tentativas(tentativas_acumuladas)
	minigame.nova_query()


func _on_resposta_correta(pontos: int) -> void:
	if tutorial.running:
		return
	PlayerData.add_points(pontos)
	_on_query_correta(pontos)


## Dá uma oportunidade 6-7 sem precisar das 5 respostas (treino do tutorial).
func ganhar_tentativa() -> void:
	tentativas_acumuladas += 1
	hud.atualizar_tentativas(tentativas_acumuladas)


# ==========================================
# CONTADOR DE QUERIES
# ==========================================

func _on_query_correta(_pontos: int) -> void:
	consultas_corretas += 1

	if consultas_corretas % QUERIES_POR_TENTATIVA == 0:
		tentativas_acumuladas += 1

		hud.atualizar_tentativas(tentativas_acumuladas)

		print(
			"Nova oportunidade 6-7: ",
			tentativas_acumuladas
		)


# ==========================================
# PREPARACAO DO DESAFIO
# ==========================================

func _preparar_desafio() -> void:
	var camada := CanvasLayer.new()
	camada.name = "RecoveryLayer"
	camada.layer = 100

	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)

	recovery_challenge = RECOVERY_SCENE.instantiate() as Control

	if recovery_challenge == null:
		push_error("Nao foi possivel carregar RecoveryChallenge")
		return

	recovery_challenge.set("modo_teste", false)
	recovery_challenge.process_mode = Node.PROCESS_MODE_ALWAYS

	recovery_challenge.hide()
	camada.add_child(recovery_challenge)

	recovery_challenge.connect(
		"desafio_finalizado",
		_on_desafio_finalizado
	)


# ==========================================
# ABRIR O DESAFIO
# ==========================================

func _on_recovery_requested() -> void:
	if desafio_em_andamento:
		return

	if recovery_challenge == null:
		return

	if tentativas_acumuladas <= 0:
		return

	if life_manager.current_lives >= life_manager.max_lifes:
		return

	desafio_em_andamento = true

	# Consome uma oportunidade
	tentativas_acumuladas -= 1
	hud.atualizar_tentativas(tentativas_acumuladas)

	# Inicia com a dificuldade atual
	recovery_challenge.call(
		"iniciar_desafio",
		consultas_corretas
	)

	recovery_challenge.show()

	# Pausa os sistemas do jogo
	get_tree().paused = true


# ==========================================
# FINALIZAR O DESAFIO
# ==========================================

func _on_desafio_finalizado(sucesso: bool) -> void:
	if not desafio_em_andamento:
		return

	if sucesso:
		life_manager.gain_life()

	# Exibe resultado por 1 segundo
	await get_tree().create_timer(1.0, true).timeout

	if not is_inside_tree():
		return

	recovery_challenge.hide()

	get_tree().paused = false
	desafio_em_andamento = false

	# Devolve foco ao SQL
	var campo = minigame.get_node_or_null("EntradaJogador")

	if campo != null:
		campo.call_deferred("grab_focus")

	desafio_6_7_terminou.emit(sucesso)


# ==========================================
# PERDA DE VIDAS
# ==========================================

func _on_pet_feeding_missed() -> void:
	som_dano.play()
	life_manager.lose_life()


func _on_sql_tempo_esgotado() -> void:
	som_dano.play()
	life_manager.lose_life()


# ==========================================
# GAME OVER
# ==========================================

func _on_dead() -> void:
	get_tree().paused = true

	var entry: Dictionary = PlayerData.submit_score()

	game_over_screen.show_results(
		PlayerData.current_score,
		entry
	)
