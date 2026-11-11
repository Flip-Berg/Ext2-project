class_name SqlInsert
extends SqlStatement
## INSERT INTO tabela (colunas) VALUES (valores)
## Na primeira versão a linha nova tem todas as colunas.

var columns: Array[Dictionary] = []
var values: Array = []


func verb() -> String:
	return "INSERT"


func execute(rows: Array) -> Dictionary:
	var out := _copy_rows(rows)
	var row := {"_id": rows.size()}
	for i in columns.size():
		row[columns[i]["name"]] = values[i]
	out.append(row)
	return _table_result(out)


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = [tok("INSERT", KEYWORD), tok("INTO", KEYWORD), tok(table.name, TABLE), tok("(", PUNCT)]
	for i in columns.size():
		if i > 0:
			tokens.append(tok(",", PUNCT))
		tokens.append(tok(columns[i]["name"], COLUMN))
	tokens.append_array([tok(")", PUNCT), tok("VALUES", KEYWORD), tok("(", PUNCT)])
	for i in values.size():
		if i > 0:
			tokens.append(tok(",", PUNCT))
		tokens.append(tok(SqlLit.to_sql(values[i]), VALUE))
	tokens.append(tok(")", PUNCT))
	return tokens


func to_pt(_table: SqlTable) -> String:
	var parts: Array[String] = []
	for i in columns.size():
		parts.append("%s %s" % [columns[i]["pt"], SqlLit.to_pt(values[i])])
	var novo := "uma nova" if table.gender == "f" else "um novo"
	return SqlPt.sentence("Cadastre %s %s: %s" % [novo, table.singular, SqlPt.join_list(parts)])


func cost() -> int:
	return 3


func canonical() -> String:
	var parts: Array[String] = []
	for i in columns.size():
		parts.append("%s = %s" % [columns[i]["name"], SqlLit.key(values[i])])
	parts.sort()
	return "INSERT INTO %s %s" % [table.name, ", ".join(parts)]


func literals() -> Array:
	var out := []
	for i in columns.size():
		out.append([columns[i], values[i]])
	return out
