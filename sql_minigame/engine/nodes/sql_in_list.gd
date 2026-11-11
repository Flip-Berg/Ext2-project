class_name SqlInList
extends SqlCondition
## coluna IN (v1, v2, ...)   — também é a forma normalizada de "col = a OR col = b".

var column: Dictionary
var values: Array


func _init(p_column: Dictionary, p_values: Array) -> void:
	column = p_column
	values = p_values


func matches(row: Dictionary) -> bool:
	for v in values:
		if SqlLit.compare(row[column["name"]], v) == 0:
			return true
	return false


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = [tok(column["name"], COLUMN), tok("IN", KEYWORD), tok("(", PUNCT)]
	for i in values.size():
		if i > 0:
			tokens.append(tok(",", PUNCT))
		tokens.append(tok(SqlLit.to_sql(values[i]), VALUE))
	tokens.append(tok(")", PUNCT))
	return tokens


func to_pt(_table: SqlTable) -> String:
	return SqlPt.in_phrase(column, values)


func cost() -> int:
	return 2


func canonical() -> String:
	var keys: Array[String] = []
	for v in values:
		var k := SqlLit.key(v)
		if not k in keys:
			keys.append(k)
	keys.sort()
	if keys.size() == 1:
		return "%s = %s" % [column["name"], keys[0]]
	return "%s IN (%s)" % [column["name"], ", ".join(keys)]


func literals() -> Array:
	return values.map(func(v): return [column, v])
