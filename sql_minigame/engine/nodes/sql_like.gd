class_name SqlLike
extends SqlCondition
## coluna LIKE 'padrão'   (% = qualquer sequência, _ = um caractere)

var column: Dictionary
var pattern: String
var _regex: RegEx


func _init(p_column: Dictionary, p_pattern: String) -> void:
	column = p_column
	pattern = p_pattern
	var expr := ""
	for ch in pattern:
		match ch:
			"%": expr += ".*"
			"_": expr += "."
			_: expr += _escape(ch)
	_regex = RegEx.create_from_string("(?i)^" + expr + "$")


func matches(row: Dictionary) -> bool:
	return _regex.search(str(row[column["name"]])) != null


func to_tokens() -> Array[Dictionary]:
	return [tok(column["name"], COLUMN), tok("LIKE", KEYWORD), tok(SqlLit.to_sql(pattern), VALUE)]


func to_pt(_table: SqlTable) -> String:
	return SqlPt.like_phrase(column, pattern)


func cost() -> int:
	return 2


func canonical() -> String:
	return "%s LIKE %s" % [column["name"], SqlLit.key(pattern)]


func literals() -> Array:
	return [[column, pattern.replace("%", "").replace("_", "")]]


static func _escape(ch: String) -> String:
	if ch in ".\\+*?[^]$(){}=!<>|:-#/":
		return "\\" + ch
	return ch
