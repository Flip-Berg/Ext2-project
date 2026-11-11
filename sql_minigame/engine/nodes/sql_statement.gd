class_name SqlStatement
extends SqlNode
## Base dos comandos (SELECT, UPDATE, DELETE, INSERT).

var table: SqlTable
var where: SqlCondition = null


## Nome do comando, para mensagens ("SELECT").
func verb() -> String:
	return ""


## Roda o comando sobre linhas falsas (cada linha é um Dictionary com "_id").
## Não altera `rows`. Devolve {"kind": "select"|"table", "ordered": bool, "rows": [...]}.
func execute(_rows: Array) -> Dictionary:
	return {}


func literals() -> Array:
	return where.literals() if where != null else []


func _where_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	if where != null:
		tokens.append(tok("WHERE", KEYWORD))
		tokens.append_array(where.to_tokens())
	return tokens


func _where_pt() -> String:
	return " " + where.to_pt(table) if where != null else ""


func _where_canonical() -> String:
	return " WHERE " + where.canonical() if where != null else ""


func _where_cost() -> int:
	return where.cost() if where != null else 0


func _matching(rows: Array) -> Array:
	if where == null:
		return rows.duplicate()
	return rows.filter(func(row: Dictionary) -> bool: return where.matches(row))


static func _copy_rows(rows: Array) -> Array:
	return rows.map(func(row: Dictionary) -> Dictionary: return row.duplicate())


static func _table_result(rows: Array) -> Dictionary:
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["_id"] < b["_id"])
	return {"kind": "table", "ordered": true, "rows": sorted}
