class_name SqlCompare
extends SqlCondition
## coluna <op> valor   (ex.: salario > 3000)

const OPS: Array[String] = ["=", "<>", "<", ">", "<=", ">="]
const FLIPPED: Dictionary = {"=": "=", "<>": "<>", "<": ">", ">": "<", "<=": ">=", ">=": "<="}

var column: Dictionary
var op: String
var value: Variant


func _init(p_column: Dictionary, p_op: String, p_value: Variant) -> void:
	column = p_column
	op = p_op
	value = p_value


func matches(row: Dictionary) -> bool:
	var c := SqlLit.compare(row[column["name"]], value)
	match op:
		"=": return c == 0
		"<>": return c != 0
		"<": return c < 0
		">": return c > 0
		"<=": return c <= 0
		">=": return c >= 0
	return false


func to_tokens() -> Array[Dictionary]:
	return [tok(column["name"], COLUMN), tok(op, OPERATOR), tok(SqlLit.to_sql(value), VALUE)]


func to_pt(_table: SqlTable) -> String:
	return SqlPt.compare_phrase(column, op, value)


func cost() -> int:
	return 1


func canonical() -> String:
	return "%s %s %s" % [column["name"], op, SqlLit.key(value)]


func literals() -> Array:
	return [[column, value]]
