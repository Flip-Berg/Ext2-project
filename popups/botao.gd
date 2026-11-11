extends TextureButton


func _ready() -> void:
	pressed.connect(on_pressed)


func on_pressed() -> void:
	var node = get_parent()

	while node != null and not node is BasePop:
		node = node.get_parent()

	if node is BasePop:
		node.close()
