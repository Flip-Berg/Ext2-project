class_name DifficultyDirector
extends Node
## Uma dificuldade só para o jogo inteiro, de 0 a 1, vinda da pontuação e do tempo.
## Ela define o tamanho das perguntas de SQL, o tipo de lacuna e o ritmo dos pop-ups.
## Enquanto uma pergunta longa está na tela, os pop-ups aparecem mais devagar.

@export var score_for_max: float = 1000.0       # pontos para chegar à dificuldade máxima
@export var seconds_for_max: float = 300.0    # tempo para chegar à dificuldade máxima
@export_range(0.0, 1.0) var score_weight: float = 0.6
## Nível inicial para cada dificuldade escolhida no login (fácil, médio, difícil).
@export var start_levels: Array[float] = [0.0, 0.2, 0.4]
## Multiplica o tempo de cada pergunta (fácil, médio, difícil). Fácil e médio dão
## mais tempo para pensar na consulta; o difícil é o jogo sem ajuda.
@export var time_scales: Array[float] = [1.5, 1.5, 1.0]
## Multiplica o intervalo entre pop-ups (fácil, médio, difícil): maior = menos pop-ups.
@export var popup_interval_scales: Array[float] = [1.5, 1.5, 1.0]

@export_group("SQL")
@export var min_budget: int = 3
@export var max_budget: int = 9
## A partir de que nível cada tipo de lacuna aparece.
@export var piece_from: float = 0.25
@export var clause_from: float = 0.5
@export var full_from: float = 0.8

@export_group("Pop-ups")
@export var popup_min_interval: float = 5.0
@export var popup_max_interval_start: float = 15.0
@export var popup_max_interval_end: float = 6.0
@export var long_question_slowdown: float = 1.5

var elapsed: float = 0.0
var long_question_active: bool = false


func _process(delta: float) -> void:
	elapsed += delta


## Quanto tempo a mais (ou a menos) cada pergunta tem nesta dificuldade.
func time_scale() -> float:
	return _for_difficulty(time_scales)


func level() -> float:
	var by_score := PlayerData.current_score / score_for_max
	var by_time := elapsed / seconds_for_max
	var start: float = start_levels[clampi(PlayerData.starting_difficulty, 0, start_levels.size() - 1)]
	return clampf(start + score_weight * by_score + (1.0 - score_weight) * by_time, 0.0, 1.0)


func sql_budget() -> int:
	return roundi(lerpf(min_budget, max_budget, level()))


func blank_mode() -> int:
	var l := level()
	if l >= full_from:
		return SqlQuestion.Mode.FULL
	if l >= clause_from:
		return SqlQuestion.Mode.CLAUSE
	if l >= piece_from:
		return SqlQuestion.Mode.PIECE
	return SqlQuestion.Mode.KEYWORD


## Intervalo (mín, máx) em segundos até o próximo pop-up.
func popup_interval_range() -> Vector2:
	var max_interval := lerpf(popup_max_interval_start, popup_max_interval_end, level())
	var interval := Vector2(popup_min_interval, maxf(max_interval, popup_min_interval))
	if long_question_active:
		interval *= long_question_slowdown
	return interval * _for_difficulty(popup_interval_scales)


func _for_difficulty(values: Array[float]) -> float:
	return values[clampi(PlayerData.starting_difficulty, 0, values.size() - 1)]
