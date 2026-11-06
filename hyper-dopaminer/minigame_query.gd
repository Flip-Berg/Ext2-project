
extends Control

@onready var texto_objetivo: Label = $TextoObjetivo
@onready var entrada_jogador: LineEdit = $EntradaJogador
@onready var label_pseudocodigo: Label = $LabelPseudocodigo
@onready var barra_tempo: ProgressBar = $BarraTempo
@onready var fundo_feedback: ColorRect = $FundoFeedback
@onready var label_feedback: Label = $LabelFeedback


var banco_queries: Array[Dictionary] = [
	{"pseudo": "-> Busque todos os dados da tabela usuários", "exibicao": "SELECT * ____ usuarios", "resposta": "FROM"},
	{"pseudo": "-> Selecione apenas a coluna nome", "exibicao": "______ nome FROM clientes", "resposta": "SELECT"},
	{"pseudo": "-> Atualize o registro de produtos", "exibicao": "______ produtos SET preco = 10", "resposta": "UPDATE"},
	{"pseudo": "-> Delete os logs antigos", "exibicao": "DELETE FROM logs ______ data < 2023", "resposta": "WHERE"},
	{"pseudo": "-> Insira um novo cliente", "exibicao": "INSERT ______ clientes VALUES ('Joao')", "resposta": "INTO"},
	{"pseudo": "-> Defina o valor de status para ativo", "exibicao": "UPDATE usuarios ______ status = 'ativo'", "resposta": "SET"}
]

var query_atual: Dictionary = {}

var tempo_maximo: float = 30.0
var tempo_restante: float = 30.0
var multiplicador_dificuldade: float = 1.0


var rodada_finalizada: bool = false

var tween_feedback: Tween
var tween_fundo: Tween


func _ready() -> void:
	entrada_jogador.text_submitted.connect(_checar_resposta)

	fundo_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo_feedback.modulate.a = 0.0
	label_feedback.modulate.a = 0.0

	barra_tempo.min_value = 0.0
	barra_tempo.max_value = 100.0

	nova_query()


func _process(delta: float) -> void:
	if rodada_finalizada:
		return

	var duracao_rodada := tempo_maximo / multiplicador_dificuldade

	tempo_restante = maxf(tempo_restante - delta, 0.0)
	barra_tempo.value = (tempo_restante / duracao_rodada) * 100.0



func nova_query() -> void:
	rodada_finalizada = false
	query_atual = banco_queries.pick_random()

	label_pseudocodigo.text = query_atual["pseudo"]
	texto_objetivo.text = query_atual["exibicao"]

	entrada_jogador.editable = true
	entrada_jogador.text = ""
	entrada_jogador.grab_focus()

	_limpar_feedback()

	tempo_restante = tempo_maximo / multiplicador_dificuldade
	barra_tempo.value = 100.0


func _checar_resposta(texto_digitado: String) -> void:
	if rodada_finalizada:
		return

	var resposta_digitada := texto_digitado.strip_edges().to_upper()
	var resposta_correta := str(query_atual["resposta"]).strip_edges().to_upper()

	if resposta_digitada == resposta_correta:
		_acertou()
	else:
		_errou()


func _acertou() -> void:
	rodada_finalizada = true
	entrada_jogador.editable = false

	multiplicador_dificuldade = minf(
		multiplicador_dificuldade + 0.05,
		1.5
	)

	_piscar_tela(Color.GREEN)
	_mostrar_feedback("ACERTOU! Próxima pergunta...", Color.GREEN)

	await get_tree().create_timer(0.65).timeout

	if is_inside_tree():
		nova_query()


func _errou() -> void:
	_piscar_tela(Color.RED)
	_mostrar_feedback("ERROU! Tente novamente.", Color.RED)

	entrada_jogador.text = ""
	entrada_jogador.grab_focus()



func _erro_por_tempo() -> void:
	if rodada_finalizada:
		return

	rodada_finalizada = true
	entrada_jogador.editable = false


func _mostrar_feedback(mensagem: String, cor: Color) -> void:
	if tween_feedback != null and tween_feedback.is_running():
		tween_feedback.kill()

	label_feedback.text = mensagem
	label_feedback.add_theme_color_override("font_color", cor)
	label_feedback.modulate.a = 1.0

	tween_feedback = create_tween()
	tween_feedback.tween_interval(0.55)
	tween_feedback.tween_property(
		label_feedback,
		"modulate:a",
		0.0,
		0.35
	)


func _limpar_feedback() -> void:
	if tween_feedback != null and tween_feedback.is_running():
		tween_feedback.kill()

	label_feedback.text = ""
	label_feedback.modulate.a = 0.0


func _piscar_tela(cor: Color) -> void:
	if tween_fundo != null and tween_fundo.is_running():
		tween_fundo.kill()

	fundo_feedback.color = cor
	fundo_feedback.modulate.a = 0.18

	tween_fundo = create_tween()
	tween_fundo.tween_property(
		fundo_feedback,
		"modulate:a",
		0.0,
		0.5
	)
