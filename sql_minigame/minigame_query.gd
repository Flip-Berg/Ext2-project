extends Control
## Minigame de SQL: mostra um pedido em português gerado por SqlGenerator, o SQL com
## uma lacuna e confere a resposta com SqlChecker. Ver res://sql/ e o design no doc.

signal resposta_correta(pontos: int)
signal tempo_esgotado
signal _continuar  # fim da revelação da resposta (tempo ou Enter)
## Só com `automatico` desligado (tutorial): a pergunta foi respondida e o minigame
## espera a próxima vir de fora, por perguntar().
signal pergunta_concluida
signal resposta_errada

const PENALIDADE_ERRO: float = 3.0       # segundos perdidos por resposta errada
const PAUSA_ACERTO: float = 0.65
# Quanto tempo a resposta certa fica na tela quando o tempo acaba (Enter pula).
const REVELACAO_MIN: float = 5.0
const REVELACAO_POR_CARACTERE: float = 0.05
const REVELACAO_MAX: float = 12.0
# Cores escuras: o painel (QueryPanel.png) é cinza claro.
const COR_PALAVRA_CHAVE: Color = Color("#6a1b9a")
const COR_COLUNA: Color = Color("#0d47a1")
const COR_TEXTO: Color = Color("#1b5e20")
const COR_NUMERO: Color = Color("#bf360c")
const COR_SIMBOLO: Color = Color("#37474f")
const COR_ACERTO: Color = Color("#1b5e20")
const COR_ERRO: Color = Color("#b71c1c")
const COR_LACUNA: Color = Color("#212121")
const FUNDO_RESPOSTA: Color = Color("#fff176")  # marca-texto na resposta revelada
const TIPOS_PT: Dictionary = {"number": "número", "text": "texto", "date": "data"}

@onready var texto_objetivo: RichTextLabel = $TextoObjetivo
@onready var entrada_jogador: CodeEdit = $EntradaJogador
@onready var label_pseudocodigo: Label = $LabelPseudocodigo
@onready var barra_tempo: ProgressBar = $BarraTempo
@onready var fundo_feedback: ColorRect = $FundoFeedback
@onready var label_feedback: Label = $LabelFeedback
@onready var painel_schema: RichTextLabel = $RichTextLabel
@onready var label_dica: RichTextLabel = $LabelDica

## Definido pela GameScene; sem ele o minigame fica na dificuldade inicial.
var director: DifficultyDirector
## Desligado, o minigame não sorteia perguntas: quem manda é o tutorial.
var automatico: bool = true
## Sem contagem de tempo (tutorial): a barra some e errar não tira segundos.
var sem_tempo: bool = false

var _rng := RandomNumberGenerator.new()
var _tabelas: Array[SqlTable] = []
var _gerador: SqlGenerator
var _parser: SqlParser
var _pergunta: SqlQuestion
var _destaque := CodeHighlighter.new()

var tempo_restante: float = 0.0
var _tempo_total: float = 1.0
var rodada_finalizada: bool = true
var _revelando: bool = false

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
	esconder_dica()
	# Espera a GameScene definir o director (ou desligar `automatico`) antes da
	# primeira pergunta.
	_iniciar.call_deferred()


func _iniciar() -> void:
	if automatico:
		nova_query()


func _process(delta: float) -> void:
	if rodada_finalizada or _pergunta == null:
		return
	_manter_foco()
	if sem_tempo:
		return
	tempo_restante = maxf(tempo_restante - delta, 0.0)
	barra_tempo.value = tempo_restante / _tempo_total * 100.0
	if tempo_restante <= 0.0:
		_erro_por_tempo()


func nova_query() -> void:
	var orcamento := director.sql_budget() if director else 3
	var modo: int = director.blank_mode() if director else SqlQuestion.Mode.KEYWORD
	perguntar(SqlQuestion.create(_gerador.generate(orcamento), modo, _rng))
	if director:
		director.long_question_active = _pergunta.is_long()


## Mostra uma pergunta pronta (sorteada por nova_query ou montada pelo tutorial).
func perguntar(pergunta: SqlQuestion) -> void:
	_pergunta = pergunta
	label_pseudocodigo.text = "-> " + _pergunta.prompt
	if _pergunta.mode == SqlQuestion.Mode.FULL:
		texto_objetivo.text = "Escreva a consulta completa."
	else:
		texto_objetivo.text = _sql_bbcode(false)
	painel_schema.text = _schema_bbcode(_pergunta.table)
	_atualizar_destaque(_pergunta.table)

	entrada_jogador.editable = true
	entrada_jogador.text = ""
	entrada_jogador.grab_focus()
	_limpar_feedback()

	_tempo_total = _pergunta.time_limit * (director.time_scale() if director else 1.0)
	tempo_restante = _tempo_total
	barra_tempo.value = 100.0
	barra_tempo.visible = not sem_tempo
	rodada_finalizada = false


## Pergunta montada à mão (tutorial). Ver SqlQuestion.with_answer().
func pergunta_fixa(sql: String, resposta: String) -> SqlQuestion:
	var resultado := _parser.parse(sql)
	if not resultado.has("tree"):
		push_error("SQL inválido: %s (%s)" % [sql, resultado.get("error", "")])
		return null
	return SqlQuestion.with_answer(resultado["tree"], resposta)


## Tira a pergunta da tela (o tutorial usa enquanto ensina pop-ups e o pet).
func limpar() -> void:
	rodada_finalizada = true
	_pergunta = null
	label_pseudocodigo.text = ""
	texto_objetivo.text = ""
	entrada_jogador.text = ""
	entrada_jogador.editable = false
	_limpar_feedback()


## Caixa de dica no pé do painel (BBCode), usada pelo tutorial.
func mostrar_dica(bbcode: String) -> void:
	label_dica.text = bbcode
	label_dica.show()


func esconder_dica() -> void:
	label_dica.hide()


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
	var pontos := _pergunta.points()
	resposta_correta.emit(pontos)
	entrada_jogador.editable = false
	_piscar_tela(Color.GREEN)
	_mostrar_feedback("ACERTOU! +%d pts" % pontos, COR_ACERTO, 0.55)
	await get_tree().create_timer(PAUSA_ACERTO, false).timeout
	if not is_inside_tree():
		return
	if automatico:
		nova_query()
	else:
		pergunta_concluida.emit()


func _errou(mensagem: String) -> void:
	# O texto fica no campo para o jogador corrigir.
	_piscar_tela(Color.RED)
	if sem_tempo:
		_mostrar_feedback("ERROU! %s" % mensagem, COR_ERRO, 4.0)
	else:
		tempo_restante = maxf(tempo_restante - PENALIDADE_ERRO, 0.0)
		_mostrar_feedback("ERROU! %s (-%ds)" % [mensagem, int(PENALIDADE_ERRO)], COR_ERRO, 2.5)
	entrada_jogador.grab_focus()
	resposta_errada.emit()


func _erro_por_tempo() -> void:
	if rodada_finalizada:
		return
	rodada_finalizada = true
	entrada_jogador.editable = false
	tempo_esgotado.emit()
	_piscar_tela(Color.DARK_RED)

	# Mostra a consulta certa inteira, com a parte que faltava marcada.
	var certa := _pergunta.revealed_sql()
	texto_objetivo.text = _sql_bbcode(true)
	var duracao := clampf(REVELACAO_MIN + certa.length() * REVELACAO_POR_CARACTERE, REVELACAO_MIN, REVELACAO_MAX)
	_mostrar_feedback("TEMPO ESGOTADO! A resposta certa está acima. (Enter para continuar)", COR_ERRO, duracao)

	_revelando = true
	get_tree().create_timer(duracao, false).timeout.connect(_fim_da_revelacao)
	await _continuar
	if is_inside_tree():
		nova_query()


func _fim_da_revelacao() -> void:
	if _revelando:
		_revelando = false
		_continuar.emit()


# --- campo de resposta (CodeEdit de uma linha com autocomplete) ---

func _configurar_entrada() -> void:
	entrada_jogador.syntax_highlighter = _destaque
	entrada_jogador.code_completion_requested.connect(_on_completion_requested)
	entrada_jogador.text_changed.connect(_on_texto_mudou)
	entrada_jogador.gui_input.connect(_on_entrada_gui_input)
	_destaque.number_color = COR_NUMERO
	_destaque.symbol_color = COR_SIMBOLO
	_destaque.function_color = Color.BLACK
	_destaque.member_variable_color = Color.BLACK
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
	if _revelando:
		entrada_jogador.accept_event()
		_fim_da_revelacao()
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
	var coluna := entrada_jogador.get_caret_column()
	# Com o cursor no começo da linha o CodeEdit não tem palavra para completar
	# (e reclama no console se receber opções).
	if _pergunta == null or rodada_finalizada or coluna == 0:
		entrada_jogador.cancel_code_completion()
		return
	var linha := entrada_jogador.get_line(0).left(coluna)
	var contexto := linha
	if _pergunta.mode != SqlQuestion.Mode.FULL:
		contexto = _pergunta.prefix_text() + " " + linha
	for s in SqlAutocomplete.suggestions(contexto, _pergunta.table):
		var tipo := CodeEdit.KIND_PLAIN_TEXT
		var cor := COR_PALAVRA_CHAVE
		match s["kind"]:
			"table":
				tipo = CodeEdit.KIND_CLASS
				cor = COR_COLUNA
			"column":
				tipo = CodeEdit.KIND_MEMBER
				cor = COR_COLUNA
			"keyword":
				tipo = CodeEdit.KIND_CONSTANT
		entrada_jogador.add_code_completion_option(tipo, s["text"], s["text"], cor)
	entrada_jogador.update_code_completion_options(true)


## O campo de resposta fica focado o jogo todo: clicar no X de um pop-up tira o foco
## (o botão some junto com o pop-up) e o jogador teria que clicar no campo de novo.
## Só devolve o foco se nenhum outro controle estiver com ele.
func _manter_foco() -> void:
	if is_visible_in_tree() and get_viewport().gui_get_focus_owner() == null:
		entrada_jogador.grab_focus()


# --- SQL colorido (o enunciado com lacuna e a resposta revelada) ---

## BBCode do SQL da pergunta com as mesmas cores do campo de resposta. Sem `revelar`,
## a lacuna aparece como ____; com `revelar`, a parte que faltava vem marcada.
func _sql_bbcode(revelar: bool) -> String:
	var itens: Array[Dictionary] = []
	for i in _pergunta.tokens.size():
		var na_lacuna := i >= _pergunta.blank_start and i < _pergunta.blank_end
		if na_lacuna and not revelar:
			if i == _pergunta.blank_start:
				itens.append({"text": SqlQuestion.BLANK, "role": "lacuna"})
			continue
		var item: Dictionary = _pergunta.tokens[i].duplicate()
		item["resposta"] = na_lacuna
		itens.append(item)

	var out := ""
	for i in itens.size():
		var texto: String = itens[i]["text"]
		# Mesmo espaçamento de SqlNode.join_tokens.
		var espaco: bool = i > 0 and not texto in [",", ")"] and itens[i - 1]["text"] != "("
		var pedaco := "[color=#%s]%s[/color]" % [_cor_do_token(itens[i]).to_html(false), texto.replace("[", "[lb]")]
		if itens[i]["role"] == "lacuna":
			pedaco = "[b]%s[/b]" % pedaco
		if itens[i].get("resposta", false):
			# O espaço entre duas partes da resposta também fica marcado.
			if espaco and i > 0 and itens[i - 1].get("resposta", false):
				pedaco = " " + pedaco
				espaco = false
			pedaco = "[bgcolor=#%s][b]%s[/b][/bgcolor]" % [FUNDO_RESPOSTA.to_html(false), pedaco]
		out += (" " if espaco else "") + pedaco
	return out


func _cor_do_token(token: Dictionary) -> Color:
	match token["role"]:
		SqlNode.KEYWORD:
			return COR_PALAVRA_CHAVE
		SqlNode.TABLE, SqlNode.COLUMN:
			return COR_COLUNA
		SqlNode.VALUE:
			return COR_TEXTO if String(token["text"]).begins_with("'") else COR_NUMERO
		"lacuna":
			return COR_LACUNA
	return COR_SIMBOLO


# --- painel do schema ---

func _schema_bbcode(tabela: SqlTable) -> String:
	var linhas: Array[String] = ["[b]Tabela: %s[/b]" % tabela.name, ""]
	for coluna in tabela.columns:
		linhas.append("[color=#0d47a1][b]%s[/b][/color]  [color=#424242]%s[/color]" % [coluna["name"], TIPOS_PT[coluna["type"]]])
		linhas.append("   [color=#424242]%s[/color]" % _exemplo(coluna))
	linhas.append("")
	linhas.append("[color=#424242]Textos e datas entre aspas: 'TI', '2024-01-31'[/color]")
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
