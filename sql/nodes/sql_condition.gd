class_name SqlCondition
extends SqlNode
## Base das condições do WHERE.


## A linha satisfaz a condição?
func matches(_row: Dictionary) -> bool:
	return false
