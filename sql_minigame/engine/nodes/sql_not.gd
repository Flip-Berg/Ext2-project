class_name SqlNot
extends SqlCondition
## NOT condição   (ainda não é gerado; aceito quando o jogador escreve)

var child: SqlCondition


func _init(p_child: SqlCondition) -> void:
	child = p_child


func matches(row: Dictionary) -> bool:
	return not child.matches(row)


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = [tok("NOT", KEYWORD), tok("(", PUNCT)]
	tokens.append_array(child.to_tokens())
	tokens.append(tok(")", PUNCT))
	return tokens


func to_pt(table: SqlTable) -> String:
	return "que não atendam a: " + child.to_pt(table)


func cost() -> int:
	return child.cost() + 1


func canonical() -> String:
	return "NOT (%s)" % child.canonical()


func literals() -> Array:
	return child.literals()
