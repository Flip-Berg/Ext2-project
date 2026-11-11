class_name SqlUpdate
extends SqlStatement
## UPDATE tabela SET coluna = valor [, ...] [WHERE ...]

var assignments: Array = []  # pares [coluna (Dictionary), valor]


func verb() -> String:
	return "UPDATE"


func execute(rows: Array) -> Dictionary:
	var out := _copy_rows(rows)
	for row in out:
		if where == null or where.matches(row):
			for pair in assignments:
				row[pair[0]["name"]] = pair[1]
	return _table_result(out)


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = [tok("UPDATE", KEYWORD), tok(table.name, TABLE), tok("SET", KEYWORD)]
	for i in assignments.size():
		if i > 0:
			tokens.append(tok(",", PUNCT))
		tokens.append_array([
			tok(assignments[i][0]["name"], COLUMN), tok("=", OPERATOR),
			tok(SqlLit.to_sql(assignments[i][1]), VALUE),
		])
	tokens.append_array(_where_tokens())
	return tokens


func to_pt(_table: SqlTable) -> String:
	var parts: Array[String] = []
	for pair in assignments:
		parts.append("%s para %s" % [SqlPt.with_article(pair[0]), SqlLit.to_pt(pair[1])])
	return SqlPt.sentence("Mude %s %s %s%s" % [
		SqlPt.join_list(parts), SqlPt.em(table.gender, true), table.plural, _where_pt()])


func cost() -> int:
	return 2 + _where_cost()


func canonical() -> String:
	var parts: Array[String] = []
	for pair in assignments:
		parts.append("%s = %s" % [pair[0]["name"], SqlLit.key(pair[1])])
	parts.sort()
	return "UPDATE %s SET %s%s" % [table.name, ", ".join(parts), _where_canonical()]


func literals() -> Array:
	var out := super()
	for pair in assignments:
		out.append(pair)
	return out
