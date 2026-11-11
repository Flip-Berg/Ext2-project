
extends Control

signal desafio_finalizado(sucesso: bool)

# ==========================================
# CONFIGURACOES
# ==========================================

const IMAGEM_6: Texture2D = preload("res://game/art/6.png")
const IMAGEM_7: Texture2D = preload("res://game/art/7.png")
const IMAGEM_FACE: Texture2D = preload("res://game/art/scary_face.png")

const TAMANHO_MAO := Vector2(200, 300)
const ALTURA_MOVIMENTO := 35.0
const ANGULO_MOVIMENTO := 15.0

const TOTAL_ENTRADAS := 67
const TEMPO_INICIAL := 12.0
const TEMPO_MINIMO := 6.0
const QUERIES_POR_NIVEL := 5

# Permite testar a cena separadamente com F6
@export var modo_teste: bool = true
@export_range(5, 100, 5) var queries_de_teste: int = 5

# ==========================================
# VARIAVEIS
# ==========================================

var mao_6: TextureRect
var mao_7: TextureRect
var face_centro: TextureRect

var mensagem: Label
var contador_label: Label
var tempo_label: Label
var barra_progresso: ProgressBar

var animacao_6: Tween
var animacao_7: Tween

var entradas_corretas: int = 0
var proxima_tecla: int = 6

var tempo_total: float = TEMPO_INICIAL
var tempo_restante: float = TEMPO_INICIAL

var desafio_ativo: bool = false
var cronometro_iniciado: bool = false


# ==========================================
# INICIALIZACAO
# ==========================================

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_criar_interface()

	if modo_teste:
		iniciar_desafio(queries_de_teste)



# ==========================================
# CRIACAO DA INTERFACE
# ==========================================

func _criar_interface() -> void:
	# Fundo totalmente preto
	var fundo := ColorRect.new()
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color.BLACK
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Area central do desafio
	var coluna := VBoxContainer.new()
	add_child(coluna)

	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.offset_left = -520.0
	coluna.offset_top = -330.0
	coluna.offset_right = 520.0
	coluna.offset_bottom = 330.0

	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 22)

	# Linha principal: 6 | FACE | 7
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 70)
	linha.custom_minimum_size = Vector2(0, 390)
	coluna.add_child(linha)

	# MAO 6
	var suporte_6 := Control.new()
	suporte_6.custom_minimum_size = TAMANHO_MAO
	linha.add_child(suporte_6)

	mao_6 = _criar_imagem(IMAGEM_6)
	suporte_6.add_child(mao_6)

	# FACE ASSUSTADORA
	var suporte_face := Control.new()
	suporte_face.custom_minimum_size = TAMANHO_MAO
	linha.add_child(suporte_face)

	face_centro = _criar_imagem(IMAGEM_FACE)
	suporte_face.add_child(face_centro)

	# MAO 7
	var suporte_7 := Control.new()
	suporte_7.custom_minimum_size = TAMANHO_MAO
	linha.add_child(suporte_7)

	mao_7 = _criar_imagem(IMAGEM_7)
	suporte_7.add_child(mao_7)

	# BARRA DE PROGRESSO
	barra_progresso = ProgressBar.new()
	barra_progresso.min_value = 0
	barra_progresso.max_value = TOTAL_ENTRADAS
	barra_progresso.value = 0
	barra_progresso.show_percentage = false
	barra_progresso.custom_minimum_size = Vector2(0, 30)
	coluna.add_child(barra_progresso)

	# INFORMACOES DE PROGRESSO E TEMPO
	var linha_status := HBoxContainer.new()
	coluna.add_child(linha_status)

	contador_label = Label.new()
	contador_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contador_label.add_theme_font_size_override("font_size", 22)
	contador_label.add_theme_color_override(
		"font_color", Color.WHITE
	)
	linha_status.add_child(contador_label)

	tempo_label = Label.new()
	tempo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tempo_label.add_theme_font_size_override("font_size", 24)
	tempo_label.add_theme_color_override(
		"font_color", Color("#ffcc66")
	)
	linha_status.add_child(tempo_label)

	# MENSAGEM AO JOGADOR
	mensagem = Label.new()
	mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensagem.add_theme_font_size_override("font_size", 22)
	coluna.add_child(mensagem)


# ==========================================
# CRIACAO DAS IMAGENS
# ==========================================

func _criar_imagem(textura: Texture2D) -> TextureRect:

	var imagem := TextureRect.new()

	imagem.texture = textura
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	imagem.size = TAMANHO_MAO
	imagem.position = Vector2.ZERO
	imagem.pivot_offset = TAMANHO_MAO / 2.0

	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return imagem


# ==========================================
# DIFICULDADE E INICIO DO DESAFIO
# ==========================================

func iniciar_desafio(total_queries_corretas: int) -> void:

	# Primeiras 5 queries: 12 segundos
	# A cada 5 queries seguintes: -1 segundo
	# Tempo minimo: 6 segundos

	var blocos: int = floori(
		float(total_queries_corretas) / QUERIES_POR_NIVEL
	)

	var reducoes: int = maxi(0, blocos - 1)

	tempo_total = maxf(
		TEMPO_MINIMO,
		TEMPO_INICIAL - float(reducoes)
	)

	tempo_restante = tempo_total
	entradas_corretas = 0
	proxima_tecla = 6
	desafio_ativo = true
	cronometro_iniciado = false

	barra_progresso.value = 0
	contador_label.text = "0 / 67 entradas"

	mensagem.text = "Comece a farmar!"
	mensagem.remove_theme_color_override("font_color")

	mao_6.position = Vector2.ZERO
	mao_7.position = Vector2.ZERO
	mao_6.rotation_degrees = 0
	mao_7.rotation_degrees = 0

	_atualizar_tempo()

	print("Desafio iniciado! Tempo: ", tempo_total)


# ==========================================
# CRONOMETRO
# ==========================================


func _process(delta: float) -> void:
	if not desafio_ativo or not cronometro_iniciado:
		return

	tempo_restante = maxf(
		0.0,
		tempo_restante - delta
	)

	_atualizar_tempo()

	if tempo_restante <= 0.0:
		_finalizar_desafio(false)


func _atualizar_tempo() -> void:
	tempo_label.text = "Tempo: %.1f s" % tempo_restante


# ==========================================
# CAPTURA DAS TECLAS
# ==========================================

func _input(event: InputEvent) -> void:

	if not desafio_ativo:
		return

	if not event is InputEventKey:
		return

	var tecla := event as InputEventKey

	if not tecla.pressed or tecla.echo:
		return

	var numero: int = 0

	match tecla.keycode:
		KEY_6, KEY_KP_6:
			numero = 6

		KEY_7, KEY_KP_7:
			numero = 7

		_:
			return

	get_viewport().set_input_as_handled()

	# Impede entradas fora da sequencia
	if numero != proxima_tecla:
		mensagem.text = "Pressione %d!" % proxima_tecla
		return
	
	if not cronometro_iniciado:
		cronometro_iniciado = true
	# Entrada correta
	entradas_corretas += 1

	if numero == 6:
		_balancar(mao_6, -ANGULO_MOVIMENTO)
		proxima_tecla = 7
	else:
		_balancar(mao_7, ANGULO_MOVIMENTO)
		proxima_tecla = 6

	# Atualiza a barra e o contador
	barra_progresso.value = entradas_corretas

	contador_label.text = "%d / %d entradas" % [
		entradas_corretas,
		TOTAL_ENTRADAS
	]

	# Verifica se completou o desafio
	if entradas_corretas >= TOTAL_ENTRADAS:
		_finalizar_desafio(true)
		return

	mensagem.text = "Farme Aura o suficiente"


# ==========================================
# FINALIZACAO
# ==========================================

func _finalizar_desafio(sucesso: bool) -> void:

	if not desafio_ativo:
		return

	desafio_ativo = false

	if sucesso:
		mensagem.text = "AURA FARMADA!"
		mensagem.add_theme_color_override(
			"font_color", Color("#66ff99")
		)
	else:
		mensagem.text = "TEMPO ESGOTADO! Tentativa perdida."
		mensagem.add_theme_color_override(
			"font_color", Color("#ff6666")
		)

	desafio_finalizado.emit(sucesso)


# ==========================================
# ANIMACAO DAS MAOS
# ==========================================

func _balancar(
	imagem: TextureRect,
	angulo: float
) -> void:

	# Interrompe a animacao anterior
	if imagem == mao_6:
		if animacao_6 != null and animacao_6.is_valid():
			animacao_6.kill()
	else:
		if animacao_7 != null and animacao_7.is_valid():
			animacao_7.kill()

	# Reinicia a posicao e a rotacao
	imagem.position = Vector2.ZERO
	imagem.rotation_degrees = 0.0

	var animacao := create_tween()

	# Sobe e gira
	animacao.tween_property(
		imagem, "position:y", -ALTURA_MOVIMENTO, 0.10
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	animacao.parallel().tween_property(
		imagem, "rotation_degrees", angulo, 0.10
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Desce e retorna
	animacao.tween_property(
		imagem, "position:y", 0.0, 0.15
	).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	animacao.parallel().tween_property(
		imagem, "rotation_degrees", 0.0, 0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if imagem == mao_6:
		animacao_6 = animacao
	else:
		animacao_7 = animacao
