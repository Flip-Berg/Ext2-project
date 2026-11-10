class_name SqlSelect
extends SqlStatement
## SELECT colunas FROM tabela [WHERE ...] [ORDER BY coluna [DESC]] [LIMIT n]

var columns: Array[String] = []   # vazio = *
var order_column: Dictionary = {} # vazio = sem ORDER BY
var order_desc: bool = false
var limit: int = -1               # -1 = sem LIMIT


func verb() -> String:
	return "SELECT"


func execute(rows: Array) -> Dictionary:
	var out := _matching(rows)
	if not order_column.is_empty():
		var col_name: String = order_column["name"]
		var desc := order_desc
		out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var c := SqlLit.compare(a[col_name], b[col_name])
			if c == 0:
				return a["_id"] < b["_id"]  # desempate fixo: as duas consultas empatam igual
			return c > 0 if desc else c < 0)
	if limit >= 0:
		out = out.slice(0, limit)
	var shown: Array[String] = columns if not columns.is_empty() else table.column_names()
	var projected := out.map(func(row: Dictionary) -> Dictionary:
		var r := {}
		for c in shown:
			r[c] = row[c]
		return r)
	return {"kind": "select", "ordered": not order_column.is_empty(), "rows": projected}


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = [tok("SELECT", KEYWORD)]
	if columns.is_empty():
		tokens.append(tok("*", COLUMN))
	for i in columns.size():
		if i > 0:
			tokens.append(tok(",", PUNCT))
		tokens.append(tok(columns[i], COLUMN))
	tokens.append_array([tok("FROM", KEYWORD), tok(table.name, TABLE)])
	tokens.append_array(_where_tokens())
	if not order_column.is_empty():
		tokens.append_array([tok("ORDER BY", KEYWORD), tok(order_column["name"], COLUMN)])
		if order_desc:
			tokens.append(tok("DESC", KEYWORD))
	if limit >= 0:
		tokens.append_array([tok("LIMIT", KEYWORD), tok(str(limit), VALUE)])
	return tokens


func to_pt(_table: SqlTable) -> String:
	var what := "todos os dados"
	if not columns.is_empty():
		var parts: Array[String] = []
		for c in columns:
			parts.append(SqlPt.with_article(table.column(c)))
		what = SqlPt.join_list(parts)
	var text := "Mostre %s %s %s%s" % [what, SqlPt.de(table.gender, true), table.plural, _where_pt()]
	if not order_column.is_empty():
		text += ", " + SqlPt.order_phrase(order_column, order_desc)
	if limit >= 0:
		text += ", " + SqlPt.limit_phrase(table, limit)
	return SqlPt.sentence(text)


func cost() -> int:
	var total := 1 + _where_cost()
	if not order_column.is_empty():
		total += 1
	if limit >= 0:
		total += 1
	return total


func canonical() -> String:
	var cols := "*"
	if not columns.is_empty() and columns.size() < table.columns.size():
		var sorted := columns.duplicate()
		sorted.sort()
		cols = ",".join(sorted)
	var text := "SELECT %s FROM %s%s" % [cols, table.name, _where_canonical()]
	if not order_column.is_empty():
		text += " ORDER BY %s %s" % [order_column["name"], "DESC" if order_desc else "ASC"]
	if limit >= 0:
		text += " LIMIT %d" % limit
	return text
