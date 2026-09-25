extends Control

@onready var rich_text_label: RichTextLabel = $MarginContainer/RichTextLabel
@onready var texture_rect: TextureRect = $TextureRect
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player_2: AudioStreamPlayer = $AudioStreamPlayer2

@export var loginscene: PackedScene 

func _ready() -> void:
	# Configurações iniciais dos elementos
	texture_rect.visible = false
	rich_text_label.bbcode_enabled = true
	rich_text_label.add_theme_font_size_override("normal_font_size", 25)
	rich_text_label.visible_ratio = 0.0
	
	# Inicia a sequência completa de animações
	_run_boot_sequence()

func _run_boot_sequence() -> void:
	var tween = create_tween()
	
	# --- ETAPA 1: Animação da BIOS (Texto) ---
	audio_stream_player.play()
	tween.tween_interval(2.0) # Espera 2s antes do texto surgir
	tween.tween_property(rich_text_label, "visible_ratio", 1.0, 1.0) # Revela o texto em 1s
	tween.tween_interval(2.0) # Mantém o texto na tela por 2s
	tween.tween_property(rich_text_label, "modulate:a", 0.0, 1.0) # Esconde o texto em fade
	
	tween.tween_interval(0.5) # Pausa entre BIOS e Logo
	
	# --- ETAPA 2: Animação do Logo do OS ---
	# Prepara a imagem do logo para o fade
	tween.tween_callback(func():
		texture_rect.visible = true
		texture_rect.modulate.a = 0.0
		audio_stream_player_2.play()
	)
	
	tween.tween_property(texture_rect, "modulate:a", 1.0, 1.0) # Fade In da logo
	tween.tween_interval(0.8) # Mantém visível por 0.8s
	tween.tween_property(texture_rect, "modulate:a", 0.0, 1.0) # Fade Out da logo
	tween.tween_interval(0.8) # Pausa final
	
	# --- ETAPA 3: Transição para a LoginScene ---
	await tween.finished # Espera TODO o tween acima terminar antes de continuar!
	_go_to_splash()

func _go_to_splash() -> void:
	# Troca para a cena de Login
	SceneTransition.change_scene_to_file("res://scenes/LoginScene.tscn", 0.5)
