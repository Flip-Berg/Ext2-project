class_name SqlChecker
## Confere a resposta do jogador contra a árvore esperada, em dois passos:
##   1. compara as árvores normalizadas (rápido e exato);
##   2. se forem diferentes, roda as duas sobre várias tabelas falsas e compara os resultados.
## Respostas equivalentes ("3000 < salario") contam como certas.

const DATASETS: int = 4
const ROWS_PER_DATASET: int = 14


## Devolve {"ok": bool, "message": String}.
static func check(expected: SqlStatement, answer: String, parser: SqlParser, rng: RandomNumberGenerator) -> Dictionary:
	var parsed := parser.parse(answer)
	if parsed.has("error"):
		return {"ok": false, "message": parsed["error"]}
	var given: SqlStatement = parsed["tree"]
	if given.verb() != expected.verb():
		return {"ok": false, "message": "O pedido é um %s." % expected.verb()}
	if given.table != expected.table:
		return {"ok": false, "message": "A tabela certa é %s." % expected.table.name}
	if given.canonical() == expected.canonical():
		return {"ok": true, "message": ""}

	var literals := expected.literals() + given.literals()
	for i in DATASETS:
		var rows := SqlFakeRows.make(expected.table, literals, ROWS_PER_DATASET, rng)
		if not results_equal(expected.execute(rows), given.execute(rows)):
			return {"ok": false, "message": _hint(expected, given)}
	return {"ok": true, "message": ""}


static func results_equal(a: Dictionary, b: Dictionary) -> bool:
	if a["kind"] != b["kind"] or a["rows"].size() != b["rows"].size():
		return false
	var left: Array = a["rows"].map(_row_key)
	var right: Array = b["rows"].map(_row_key)
	if not a["ordered"]:
		left.sort()
		right.sort()
	return left == right


static func _row_key(row: Dictionary) -> String:
	var keys := row.keys()
	keys.sort()
	var parts := []
	for k in keys:
		parts.append("%s=%s" % [k, SqlLit.key(row[k])])
	return "|".join(parts)


static func _hint(expected: SqlStatement, given: SqlStatement) -> String:
	if expected.where != null and given.where == null:
		return "Faltou o WHERE."
	if expected is SqlSelect:
		if not expected.order_column.is_empty() and given.order_column.is_empty():
			return "Faltou o ORDER BY."
		if expected.limit >= 0 and given.limit < 0:
			return "Faltou o LIMIT."
	return "O resultado não bate com o pedido."
