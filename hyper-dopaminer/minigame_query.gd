extends Control
## Minigame de SQL: mostra um pedido em português gerado por SqlGenerator, o SQL com
## uma lacuna e confere a resposta com SqlChecker. Ver res://sql/ e o design no doc.

signal resposta_correta
signal tempo_esgotado

const PENALIDADE_ERRO: float = 3.0       # segundos perdidos por resposta errada
const PAUSA_ACERTO: float = 0.65
const PAUSA_TEMPO_ESGOTADO: float = 2.5
const COR_PALAVRA_CHAVE: Color = Color("#c792ea")
const COR_COLUNA: Color = Color("#82aaff")
const COR_TEXTO: Color = Color("#c3e88d")
const COR_NUMERO: Color = Color("#f78c6c")
const COR_SIMBOLO: Color = Color("#89ddff")
const TIPOS_PT: Dictionary = {"number": "número", "text": "texto", "date": "data"}

@onready var texto_objetivo: Label = $TextoObjetivo
@onready var entrada_jogador: CodeEdit = $EntradaJogador
@onready var label_pseudocodigo: Label = $LabelPseudocodigo
@onready var barra_tempo: ProgressBar = $BarraTempo
@onready var fundo_feedback: ColorRect = $FundoFeedback
@onready var label_feedback: Label = $LabelFeedback
@onready var painel_schema: RichTextLabel = $RichTextLabel

## Definido pela GameScene; sem ele o minigame fica na dificuldade inicial.
var director: DifficultyDirector

var _rng := RandomNumberGenerator.new()
var _tabelas: Array[SqlTable] = []
var _gerador: SqlGenerator
var _parser: SqlParser
var _pergunta: SqlQuestion
var _destaque := CodeHighlighter.new()

var tempo_restante: float = 0.0
var rodada_finalizada: bool = true

var tween_feedback: Tween
var tween_fundo: Tween


func _ready() -> void:
	_rng.randomize()
	_tabelas = SqlTable.load_all()
	_gerador = SqlGenerator.new(_tabelas, _rng)
	_parser = SqlParser.new(_tabelas)

	fundo_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo_feedback.modulate.a = 0.0
	label_feedback.modulate.a = 0.0
	barra_tempo.min_value = 0.0
	barra_tempo.max_value = 100.0

	_configurar_entrada()
	# Espera a GameScene definir o director antes da primeira pergunta.
	nova_query.call_deferred()


func _process(delta: float) -> void:
	if rodada_finalizada or _pergunta == null:
		return
	tempo_restante = maxf(tempo_restante - delta, 0.0)
	barra_tempo.value = tempo_restante / _pergunta.time_limit * 100.0
	if tempo_restante <= 0.0:
		_erro_por_tempo()


func nova_query() -> void:
	var orcamento := director.sql_budget() if director else 3
	var modo: int = director.blank_mode() if director else SqlQuestion.Mode.KEYWORD
	_pergunta = SqlQuestion.create(_gerador.generate(orcamento), modo, _rng)

	label_pseudocodigo.text = "-> " + _pergunta.prompt
	if _pergunta.mode == SqlQuestion.Mode.FULL:
		texto_objetivo.text = "Escreva a consulta completa."
	else:
		texto_objetivo.text = _pergunta.shown_sql()
	painel_schema.text = _schema_bbcode(_pergunta.table)
	_atualizar_destaque(_pergunta.table)

	entrada_jogador.editable = true
	entrada_jogador.text = ""
	entrada_jogador.grab_focus()
	_limpar_feedback()

	tempo_restante = _pergunta.time_limit
	barra_tempo.value = 100.0
	rodada_finalizada = false
	if director:
		director.long_question_active = _pergunta.is_long()


func _enviar() -> void:
	if rodada_finalizada:
		return
	var digitado := entrada_jogador.text.strip_edges()
	if digitado == "":
		return
	var resultado := SqlChecker.check(_pergunta.tree, _pergunta.full_answer(digitado), _parser, _rng)
	if resultado["ok"]:
		_acertou()
	else:
		_errou(resultado["message"])


func _acertou() -> void:
	rodada_finalizada = true
	resposta_correta.emit()
	entrada_jogador.editable = false
	_piscar_tela(Color.GREEN)
	_mostrar_feedback("ACERTOU! Próxima pergunta...", Color.GREEN, 0.55)
	await get_tree().create_timer(PAUSA_ACERTO, false).timeout
	if is_inside_tree():
		nova_query()


func _errou(mensagem: String) -> void:
	# O texto fica no campo para o jogador corrigir.
	tempo_restante = maxf(tempo_restante - PENALIDADE_ERRO, 0.0)
	_piscar_tela(Color.RED)
	_mostrar_feedback("ERROU! %s (-%ds)" % [mensagem, int(PENALIDADE_ERRO)], Color.RED, 2.5)
	entrada_jogador.grab_focus()


func _erro_por_tempo() -> void:
	if rodada_finalizada:
		return
	rodada_finalizada = true
	entrada_jogador.editable = false
	tempo_esgotado.emit()
	_piscar_tela(Color.DARK_RED)
	_mostrar_feedback("TEMPO ESGOTADO! Resposta: %s" % _pergunta.answer_text(), Color.RED, PAUSA_TEMPO_ESGOTADO - 0.4)
	await get_tree().create_timer(PAUSA_TEMPO_ESGOTADO, false).timeout
	if is_inside_tree():
		nova_query()


# --- campo de resposta (CodeEdit de uma linha com autocomplete) ---

func _configurar_entrada() -> void:
	entrada_jogador.syntax_highlighter = _destaque
	entrada_jogador.code_completion_requested.connect(_on_completion_requested)
	entrada_jogador.text_changed.connect(_on_texto_mudou)
	entrada_jogador.gui_input.connect(_on_entrada_gui_input)
	_destaque.number_color = COR_NUMERO
	_destaque.symbol_color = COR_SIMBOLO
	_destaque.function_color = Color.WHITE
	_destaque.member_variable_color = Color.WHITE
	_destaque.add_color_region("'", "'", COR_TEXTO, false)
	_destaque.add_color_region("\"", "\"", COR_TEXTO, false)


func _atualizar_destaque(tabela: SqlTable) -> void:
	_destaque.clear_keyword_colors()
	for kw in SqlTokenizer.KEYWORDS:
		_destaque.add_keyword_color(kw, COR_PALAVRA_CHAVE)
		_destaque.add_keyword_color(kw.to_lower(), COR_PALAVRA_CHAVE)
	_destaque.add_keyword_color(tabela.name, COR_COLUNA)
	for coluna in tabela.column_names():
		_destaque.add_keyword_color(coluna, COR_COLUNA)


func _on_entrada_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER]):
		return
	# Enter com a lista de sugestões aberta escolhe a sugestão; senão, envia.
	if entrada_jogador.get_code_completion_selected_index() >= 0:
		return
	entrada_jogador.accept_event()
	_enviar()


func _on_texto_mudou() -> void:
	# Mantém uma linha só (colar texto com quebras, por exemplo).
	if "\n" in entrada_jogador.text:
		var coluna := entrada_jogador.get_caret_column()
		entrada_jogador.text = entrada_jogador.text.replace("\n", " ")
		entrada_jogador.set_caret_column(coluna)
	entrada_jogador.request_code_completion(true)


func _on_completion_requested() -> void:
	if _pergunta == null or rodada_finalizada:
		return
	var linha := entrada_jogador.get_line(0).left(entrada_jogador.get_caret_column())
	var contexto := linha
	if _pergunta.mode != SqlQuestion.Mode.FULL:
		contexto = _pergunta.prefix_text() + " " + linha
	var com_palavras_chave := director.keyword_suggestions() if director else true
	for s in SqlAutocomplete.suggestions(contexto, _pergunta.table, com_palavras_chave):
		var tipo := CodeEdit.KIND_PLAIN_TEXT
		match s["kind"]:
			"table": tipo = CodeEdit.KIND_CLASS
			"column": tipo = CodeEdit.KIND_MEMBER
			"keyword": tipo = CodeEdit.KIND_CONSTANT
		entrada_jogador.add_code_completion_option(tipo, s["text"], s["text"])
	entrada_jogador.update_code_completion_options(true)


# --- painel do schema ---

func _schema_bbcode(tabela: SqlTable) -> String:
	var linhas: Array[String] = ["[b]Tabela: %s[/b]" % tabela.name, ""]
	for coluna in tabela.columns:
		linhas.append("[color=#82aaff]%s[/color]  [color=gray]%s[/color]" % [coluna["name"], TIPOS_PT[coluna["type"]]])
		linhas.append("   [color=gray]%s[/color]" % _exemplo(coluna))
	linhas.append("")
	linhas.append("[color=gray]Textos e datas entre aspas: 'TI', '2024-01-31'[/color]")
	return "\n".join(linhas)


func _exemplo(coluna: Dictionary) -> String:
	match coluna["type"]:
		"number":
			return "de %d a %d" % [coluna["min"], coluna["max"]]
		"date":
			return "de '%s' a '%s'" % [coluna["min"], coluna["max"]]
	var valores: Array = coluna["values"]
	var mostrados := valores.slice(0, 5).map(func(v): return "'%s'" % v)
	return ", ".join(mostrados) + (", ..." if valores.size() > 5 else "")


# --- feedback visual ---

func _mostrar_feedback(mensagem: String, cor: Color, duracao: float) -> void:
	if tween_feedback != null and tween_feedback.is_running():
		tween_feedback.kill()
	label_feedback.text = mensagem
	label_feedback.add_theme_color_override("font_color", cor)
	label_feedback.modulate.a = 1.0
	tween_feedback = create_tween()
	tween_feedback.tween_interval(duracao)
	tween_feedback.tween_property(label_feedback, "modulate:a", 0.0, 0.35)


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
	tween_fundo.tween_property(fundo_feedback, "modulate:a", 0.0, 0.5)
