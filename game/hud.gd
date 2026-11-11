
extends CanvasLayer

signal recovery_requested

const HEART_TEXTURE: Texture2D = preload(
	"res://game/art/coracao.png"
)

const HEART_SIZE := Vector2(48, 48)

@onready var lives_container: HBoxContainer = $LivesContainer
@onready var life_manager: LifeManager = $"../LifeManager"
@onready var score_label: Label = $ScoreLabel
@onready var recovery_icon: TextureRect = $RecoveryIcon

var recovery_badge: Label
var tentativas_mostradas: int = 0


func _ready() -> void:
	life_manager.life_lost.connect(_on_lives_changed)
	life_manager.life_gained.connect(_on_lives_changed)

	_update_lives(life_manager.current_lives)

	PlayerData.score_changed.connect(_on_score_changed)
	_on_score_changed(PlayerData.current_score)

	_configurar_recovery_icon()
	atualizar_tentativas(0)


# ==========================================
# PONTUACAO
# ==========================================

func _on_score_changed(score: int) -> void:
	score_label.text = "%d pts" % score


# ==========================================
# VIDAS
# ==========================================

func _on_lives_changed(current_lives: int) -> void:
	_update_lives(current_lives)
	_atualizar_estado_recuperacao()


func _update_lives(current_lives: int) -> void:
	for child in lives_container.get_children():
		lives_container.remove_child(child)
		child.queue_free()

	for i in range(current_lives):
		var heart := TextureRect.new()
		heart.texture = HEART_TEXTURE
		heart.custom_minimum_size = HEART_SIZE
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lives_container.add_child(heart)

	# Evita sobreposicao com a pontuacao ao chegar a 7 vidas
	score_label.position.x = maxf(
		168.0,
		float(current_lives) * 53.0 + 20.0
	)


# ==========================================
# ICONE 6-7
# ==========================================

func _configurar_recovery_icon() -> void:
	# Imagem ja desenhada no fundo
	recovery_icon.texture = null

	# Agora o icone recebe cliques
	recovery_icon.mouse_filter = Control.MOUSE_FILTER_STOP

	recovery_icon.set_anchors_preset(
		Control.PRESET_CENTER_BOTTOM
	)

	# Mantemos a posicao configurada anteriormente
	recovery_icon.offset_left = 185.0
	recovery_icon.offset_top = -64.0
	recovery_icon.offset_right = 245.0
	recovery_icon.offset_bottom = -9.0

	# Fundo do contador
	var badge_panel := Panel.new()
	badge_panel.name = "CountBadge"
	recovery_icon.add_child(badge_panel)

	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	badge_panel.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	badge_panel.offset_left = -25.0
	badge_panel.offset_top = -8.0
	badge_panel.offset_right = 3.0
	badge_panel.offset_bottom = 20.0

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#202632")
	estilo.border_color = Color.WHITE
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(14)

	badge_panel.add_theme_stylebox_override(
		"panel", estilo
	)

	# Numero do contador
	recovery_badge = Label.new()
	recovery_badge.name = "Number"
	badge_panel.add_child(recovery_badge)

	recovery_badge.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	recovery_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recovery_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	recovery_badge.add_theme_font_size_override("font_size", 15)
	recovery_badge.add_theme_color_override("font_color", Color.WHITE)
	recovery_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Detecta o clique
	recovery_icon.gui_input.connect(
		_on_recovery_icon_gui_input
	)


# ==========================================
# CONTADOR DE OPORTUNIDADES
# ==========================================

func atualizar_tentativas(quantidade: int) -> void:
	tentativas_mostradas = quantidade

	recovery_icon.visible = quantidade > 0
	recovery_badge.text = str(quantidade)

	_atualizar_estado_recuperacao()


func _atualizar_estado_recuperacao() -> void:
	if not is_instance_valid(recovery_icon):
		return

	var disponivel := (
		tentativas_mostradas > 0
		and life_manager.current_lives < life_manager.max_lifes
	)

	if disponivel:
		recovery_icon.modulate = Color.WHITE
		recovery_icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		recovery_icon.modulate = Color(1, 1, 1, 0.55)
		recovery_icon.mouse_default_cursor_shape = Control.CURSOR_ARROW


# ==========================================
# CLIQUE NO ICONE
# ==========================================

func _on_recovery_icon_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var clique := event as InputEventMouseButton

	if clique.button_index != MOUSE_BUTTON_LEFT or not clique.pressed:
		return

	# Nao permite utilizar sem oportunidades
	if tentativas_mostradas <= 0:
		return

	# Nao permite utilizar com 7 vidas
	if life_manager.current_lives >= life_manager.max_lifes:
		return

	recovery_icon.accept_event()
	recovery_requested.emit()
