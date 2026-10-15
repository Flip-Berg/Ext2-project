extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# Começa totalmente transparente e sem bloquear cliques
	color_rect.color.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Função principal para trocar de cena com Fade
func change_scene_to_file(target_scene_path: String, duration: float = 0.5) -> void:
	# Bloqueia cliques do usuário durante a transição
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 1. Fade Out (Tela ficando preta)
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "color:a", 1.0, duration)
	await tween_out.finished
	
	# 2. Troca a cena na árvore do jogo
	get_tree().change_scene_to_file(target_scene_path)
	
	# Pequena pausa opcional para a nova cena carregar suavemente
	await get_tree().create_timer(0.1).timeout
	
	# 3. Fade In (A nova tela aparecendo)
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "color:a", 0.0, duration)
	await tween_in.finished
	
	# Libera os cliques do mouse novamente
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
