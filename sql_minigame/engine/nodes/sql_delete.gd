class_name SqlDelete
extends SqlStatement
## DELETE FROM tabela [WHERE ...]


func verb() -> String:
	return "DELETE"


func execute(rows: Array) -> Dictionary:
	var kept := _copy_rows(rows).filter(func(row: Dictionary) -> bool:
		return where != null and not where.matches(row))
	return _table_result(kept)


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = [tok("DELETE", KEYWORD), tok("FROM", KEYWORD), tok(table.name, TABLE)]
	tokens.append_array(_where_tokens())
	return tokens


func to_pt(_table: SqlTable) -> String:
	return SqlPt.sentence("Apague %s %s%s" % [SqlPt.article(table.gender, true), table.plural, _where_pt()])


func cost() -> int:
	return 2 + _where_cost()


func canonical() -> String:
	return "DELETE FROM %s%s" % [table.name, _where_canonical()]
