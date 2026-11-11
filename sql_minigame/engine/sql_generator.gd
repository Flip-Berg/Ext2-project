class_name SqlGenerator
extends RefCounted
## Gera uma árvore de consulta aleatória dentro de um orçamento de dificuldade.
## Cada nó tem um custo (cost()); o gerador escolhe partes até gastar o orçamento.
## Primeira versão: AND entre colunas diferentes, "OU" só dentro de uma coluna (IN).

const MAX_ATTEMPTS: int = 40
const SANITY_ROWS: int = 20
const MAX_CONDITIONS: int = 3

var tables: Array[SqlTable]
var rng: RandomNumberGenerator


func _init(p_tables: Array[SqlTable], p_rng: RandomNumberGenerator) -> void:
	tables = p_tables
	rng = p_rng


func generate(budget: int) -> SqlStatement:
	var statement: SqlStatement = null
	for attempt in MAX_ATTEMPTS:
		statement = _statement(maxi(budget, 1))
		if _is_sane(statement):
			return statement
	return statement


func _statement(budget: int) -> SqlStatement:
	var table: SqlTable = tables[rng.randi_range(0, tables.size() - 1)]
	var kinds := {"select": 5}
	if budget >= 3 and not _editable(table).is_empty():
		kinds["update"] = 2
	if budget >= 3:
		kinds["delete"] = 2
	if budget >= 4:
		kinds["insert"] = 1
	match _weighted(kinds):
		"update": return _update(table, budget)
		"delete": return _delete(table, budget)
		"insert": return _insert(table)
	return _select(table, budget)


func _select(table: SqlTable, budget: int) -> SqlSelect:
	var node := SqlSelect.new()
	node.table = table
	if rng.randf() >= 0.3:
		var names := table.column_names()
		_shuffle(names)
		var picked := names.slice(0, rng.randi_range(1, mini(3, names.size() - 1)))
		for c in table.column_names():  # mantém a ordem do schema
			if c in picked:
				node.columns.append(c)
	var remaining := budget - 1
	node.where = _where(table, remaining, [])
	remaining -= node.where.cost() if node.where != null else 0
	if remaining >= 1 and rng.randf() < (0.4 if budget < 5 else 0.8):
		node.order_column = table.columns[rng.randi_range(0, table.columns.size() - 1)]
		node.order_desc = rng.randf() < 0.5
		remaining -= 1
		if remaining >= 1 and rng.randf() < (0.4 if budget < 5 else 0.8):
			node.limit = rng.randi_range(2, 5)
	return node


func _update(table: SqlTable, budget: int) -> SqlUpdate:
	var node := SqlUpdate.new()
	node.table = table
	var editable := _editable(table)
	var target: Dictionary = editable[rng.randi_range(0, editable.size() - 1)]
	node.assignments.append([target, SqlFakeRows.random_value(target, rng)])
	node.where = _where(table, maxi(budget - 2, 1), [target["name"]], true)
	return node


func _delete(table: SqlTable, budget: int) -> SqlDelete:
	var node := SqlDelete.new()
	node.table = table
	node.where = _where(table, maxi(budget - 2, 1), [], true)
	return node


func _insert(table: SqlTable) -> SqlInsert:
	var node := SqlInsert.new()
	node.table = table
	node.columns.assign(table.columns)
	for col in table.columns:
		node.values.append(SqlFakeRows.random_value(col, rng))
	return node


## Uma ou mais condições ligadas por AND, cada uma numa coluna diferente.
func _where(table: SqlTable, budget: int, avoid: Array, required: bool = false) -> SqlCondition:
	var parts: Array[SqlCondition] = []
	var remaining := budget
	var columns := table.columns.filter(func(c: Dictionary) -> bool: return not c["name"] in avoid)
	_shuffle(columns)
	for col in columns:
		if parts.size() >= MAX_CONDITIONS or remaining < 1:
			break
		if not parts.is_empty() and rng.randf() < (0.5 if remaining < 3 else 0.1):
			break
		if parts.is_empty() and not required and rng.randf() < 0.15:
			break
		var condition := _condition(col, remaining)
		if condition != null:
			parts.append(condition)
			remaining -= condition.cost()
	if parts.is_empty():
		return null
	return parts[0] if parts.size() == 1 else SqlAnd.new(parts)


func _condition(col: Dictionary, budget: int) -> SqlCondition:
	var options := []
	match col["type"]:
		"number", "date":
			options.append("compare")
			if budget >= 2:
				options.append("between")
		"text":
			if col.has("values") and col["values"].size() <= 6:
				options.append("equals")
				options.append("not_equals")
				if budget >= 2:
					options.append("in")
			if col.get("like", false) and budget >= 2:
				options.append("like")
	if options.is_empty():
		return null
	match options[rng.randi_range(0, options.size() - 1)]:
		"compare":
			var op: String = [">", "<", ">=", "<=", ">", "<"][rng.randi_range(0, 5)]
			return SqlCompare.new(col, op, SqlFakeRows.random_value(col, rng))
		"between":
			var a: Variant = SqlFakeRows.random_value(col, rng)
			var b: Variant = SqlFakeRows.random_value(col, rng)
			if SqlLit.compare(a, b) == 0:
				return SqlCompare.new(col, ">", a)
			return SqlBetween.new(col, a, b) if SqlLit.compare(a, b) < 0 else SqlBetween.new(col, b, a)
		"equals":
			return SqlCompare.new(col, "=", SqlFakeRows.random_value(col, rng))
		"not_equals":
			return SqlCompare.new(col, "<>", SqlFakeRows.random_value(col, rng))
		"in":
			var values: Array = col["values"].duplicate()
			_shuffle(values)
			return SqlInList.new(col, values.slice(0, rng.randi_range(2, mini(3, values.size()))))
		"like":
			var word: String = SqlFakeRows.random_value(col, rng)
			return SqlLike.new(col, word.left(1) + "%")
	return null


## Descarta consultas que não pegam nenhuma linha, ou pegam todas.
func _is_sane(statement: SqlStatement) -> bool:
	if statement.where == null:
		return true
	var rows := SqlFakeRows.make(statement.table, statement.literals(), SANITY_ROWS, rng)
	var hits := rows.filter(func(row: Dictionary) -> bool: return statement.where.matches(row)).size()
	return hits > 0 and hits < rows.size()


func _editable(table: SqlTable) -> Array:
	return table.columns.filter(func(c: Dictionary) -> bool: return c.get("editable", false))


## Embaralha com o rng da instância (Array.shuffle() usaria o aleatório global).
func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp


func _weighted(weights: Dictionary) -> String:
	var total := 0
	for w in weights.values():
		total += w
	var roll := rng.randi_range(1, total)
	for key in weights:
		roll -= weights[key]
		if roll <= 0:
			return key
	return weights.keys()[0]
