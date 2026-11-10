class_name SqlAnd
extends SqlCondition
## c1 AND c2 AND ...

var children: Array[SqlCondition] = []


func _init(p_children: Array[SqlCondition]) -> void:
	# A AND (B AND C) vira A AND B AND C.
	for child in p_children:
		if child is SqlAnd:
			children.append_array(child.children)
		else:
			children.append(child)


func matches(row: Dictionary) -> bool:
	for child in children:
		if not child.matches(row):
			return false
	return true


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	for i in children.size():
		if i > 0:
			tokens.append(tok("AND", KEYWORD))
		var child_tokens := children[i].to_tokens()
		if children[i] is SqlOr:
			tokens.append(tok("(", PUNCT))
			tokens.append_array(child_tokens)
			tokens.append(tok(")", PUNCT))
		else:
			tokens.append_array(child_tokens)
	return tokens


func to_pt(table: SqlTable) -> String:
	var parts: Array[String] = []
	for child in children:
		parts.append(child.to_pt(table))
	return SqlPt.join_list(parts)


func cost() -> int:
	var total := 0
	for child in children:
		total += child.cost()
	return total


func canonical() -> String:
	var parts: Array[String] = []
	for child in children:
		var c := child.canonical()
		parts.append("(%s)" % c if " OR " in c else c)
	parts.sort()
	return " AND ".join(parts)


func literals() -> Array:
	var out := []
	for child in children:
		out.append_array(child.literals())
	return out
