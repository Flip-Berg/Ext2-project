class_name SqlBetween
extends SqlCondition
## coluna BETWEEN baixo AND alto   (inclusivo nos dois lados)

var column: Dictionary
var low: Variant
var high: Variant


func _init(p_column: Dictionary, p_low: Variant, p_high: Variant) -> void:
	column = p_column
	low = p_low
	high = p_high


func matches(row: Dictionary) -> bool:
	var v = row[column["name"]]
	return SqlLit.compare(v, low) >= 0 and SqlLit.compare(v, high) <= 0


func to_tokens() -> Array[Dictionary]:
	return [
		tok(column["name"], COLUMN), tok("BETWEEN", KEYWORD), tok(SqlLit.to_sql(low), VALUE),
		tok("AND", KEYWORD), tok(SqlLit.to_sql(high), VALUE),
	]


func to_pt(_table: SqlTable) -> String:
	return SqlPt.between_phrase(column, low, high)


func cost() -> int:
	return 2


func canonical() -> String:
	return "%s BETWEEN %s AND %s" % [column["name"], SqlLit.key(low), SqlLit.key(high)]


func literals() -> Array:
	return [[column, low], [column, high]]
