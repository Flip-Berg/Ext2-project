extends BasePop

signal request(position: Vector2)


func close() -> void:
	request.emit(global_position)
	super()
