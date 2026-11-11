class_name SqlParser
extends RefCounted
## Lê o SQL do jogador e monta a mesma árvore que o gerador usa.
## parse() devolve {"tree": SqlStatement} ou {"error": "mensagem em português"}.
##
## Gramática aceita:
##   SELECT (* | col, ...) FROM tab [WHERE cond] [ORDER BY col [ASC|DESC]] [LIMIT n]
##   UPDATE tab SET col = valor, ... [WHERE cond]
##   DELETE FROM tab [WHERE cond]
##   INSERT INTO tab [(col, ...)] VALUES (valor, ...)
##   cond: termo (OR termo)* ; termo: fator (AND fator)* ; fator: NOT fator | (cond) | predicado
##   predicado: col op valor | valor op col | col [NOT] IN (...) | col BETWEEN a AND b | col LIKE 'x'

var _tables: Array[SqlTable]
var _tokens: Array[Dictionary] = []
var _i: int = 0
var _error: String = ""
var _table: SqlTable


func _init(tables: Array[SqlTable]) -> void:
	_tables = tables


func parse(text: String) -> Dictionary:
	var tokenizer := SqlTokenizer.new()
	_tokens = tokenizer.tokenize(text)
	if tokenizer.error != "":
		return {"error": tokenizer.error}
	_i = 0
	_error = ""
	_table = null

	var statement: SqlStatement = null
	match _peek()["text"]:
		"SELECT": statement = _select()
		"UPDATE": statement = _update()
		"DELETE": statement = _delete()
		"INSERT": statement = _insert()
		_: return {"error": "A consulta deve começar com SELECT, UPDATE, DELETE ou INSERT."}

	if _error == "":
		_accept("punct", ";")
		if _peek()["type"] != "eof":
			_fail("Sobrou texto no fim da consulta: \"%s\"." % _peek()["text"])
	if _error != "":
		return {"error": _error}
	return {"tree": statement}


# --- comandos ---

func _select() -> SqlSelect:
	var node := SqlSelect.new()
	_expect_kw("SELECT")
	var names: Array[String] = []
	if not _accept("punct", "*"):
		names.append(_expect_ident("o nome de uma coluna"))
		while _error == "" and _accept("punct", ","):
			names.append(_expect_ident("o nome de uma coluna"))
	_expect_kw("FROM")
	node.table = _resolve_table()
	for column_name in names:
		var col := _resolve_column(column_name)
		if _error != "":
			return null
		node.columns.append(col["name"])
	if _accept_kw("WHERE"):
		node.where = _condition()
	if _accept_kw("ORDER"):
		_expect_kw("BY")
		node.order_column = _resolve_column(_expect_ident("a coluna do ORDER BY"))
		if _accept_kw("DESC"):
			node.order_desc = true
		else:
			_accept_kw("ASC")
	if _accept_kw("LIMIT"):
		var t := _peek()
		if t["type"] != "number" or not t["value"] is int or t["value"] < 0:
			_fail("Depois de LIMIT vem um número inteiro.")
		else:
			_i += 1
			node.limit = t["value"]
	return node


func _update() -> SqlUpdate:
	var node := SqlUpdate.new()
	_expect_kw("UPDATE")
	node.table = _resolve_table()
	_expect_kw("SET")
	while _error == "":
		var col := _resolve_column(_expect_ident("a coluna a alterar"))
		_expect_op("=")
		var value: Variant = _literal_for(col)
		node.assignments.append([col, value])
		if not _accept("punct", ","):
			break
	if _accept_kw("WHERE"):
		node.where = _condition()
	return node


func _delete() -> SqlDelete:
	var node := SqlDelete.new()
	_expect_kw("DELETE")
	_expect_kw("FROM")
	node.table = _resolve_table()
	if _accept_kw("WHERE"):
		node.where = _condition()
	return node


func _insert() -> SqlInsert:
	var node := SqlInsert.new()
	_expect_kw("INSERT")
	_expect_kw("INTO")
	node.table = _resolve_table()
	if _error != "":
		return null
	if _accept("punct", "("):
		while _error == "":
			var col := _resolve_column(_expect_ident("o nome de uma coluna"))
			if _error == "":
				node.columns.append(col)
			if not _accept("punct", ","):
				break
		_expect("punct", ")")
	else:
		node.columns.assign(_table.columns)
	_expect_kw("VALUES")
	_expect("punct", "(")
	var index := 0
	while _error == "":
		if index >= node.columns.size():
			_fail("Há mais valores do que colunas.")
			break
		node.values.append(_literal_for(node.columns[index]))
		index += 1
		if not _accept("punct", ","):
			break
	_expect("punct", ")")
	if _error == "" and node.values.size() < node.columns.size():
		_fail("Faltam valores: são %d colunas e %d valores." % [node.columns.size(), node.values.size()])
	if _error == "" and node.columns.size() < _table.columns.size():
		_fail("Informe todas as colunas: %s." % ", ".join(_table.column_names()))
	return node


# --- condições ---

func _condition() -> SqlCondition:
	var parts: Array[SqlCondition] = [_and_term()]
	while _error == "" and _accept_kw("OR"):
		parts.append(_and_term())
	if _error != "":
		return null
	return parts[0] if parts.size() == 1 else SqlOr.new(parts)


func _and_term() -> SqlCondition:
	var parts: Array[SqlCondition] = [_factor()]
	while _error == "" and _accept_kw("AND"):
		parts.append(_factor())
	if _error != "":
		return null
	return parts[0] if parts.size() == 1 else SqlAnd.new(parts)


func _factor() -> SqlCondition:
	if _accept_kw("NOT"):
		var inner := _factor()
		return SqlNot.new(inner) if _error == "" else null
	if _accept("punct", "("):
		var inner := _condition()
		_expect("punct", ")")
		return inner
	return _predicate()


func _predicate() -> SqlCondition:
	var t := _peek()
	# valor op coluna  ->  coluna op' valor
	if t["type"] in ["number", "string"]:
		_i += 1
		var op_token := _peek()
		if op_token["type"] != "op":
			_fail("Esperava um operador (=, <, >, ...) depois de %s." % t["text"])
			return null
		_i += 1
		var col := _resolve_column(_expect_ident("o nome de uma coluna"))
		if _error != "":
			return null
		_check_literal(col, t)
		return SqlCompare.new(col, SqlCompare.FLIPPED[op_token["text"]], t["value"]) if _error == "" else null

	var col := _resolve_column(_expect_ident("o nome de uma coluna"))
	if _error != "":
		return null
	var negate := _accept_kw("NOT")
	if _accept_kw("IN"):
		_expect("punct", "(")
		var values := [_literal_for(col)]
		while _error == "" and _accept("punct", ","):
			values.append(_literal_for(col))
		_expect("punct", ")")
		if _error != "":
			return null
		var node := SqlInList.new(col, values)
		return SqlNot.new(node) if negate else node
	if negate:
		_fail("Depois de NOT aqui, esperava IN.")
		return null
	if _accept_kw("BETWEEN"):
		var low: Variant = _literal_for(col)
		_expect_kw("AND")
		var high: Variant = _literal_for(col)
		return SqlBetween.new(col, low, high) if _error == "" else null
	if _accept_kw("LIKE"):
		var p := _peek()
		if p["type"] != "string":
			_fail("Depois de LIKE vem um texto entre aspas, como 'A%'.")
			return null
		_i += 1
		return SqlLike.new(col, p["value"])
	var op_token := _peek()
	if op_token["type"] != "op":
		_fail("Esperava um operador (=, <, >, IN, BETWEEN, LIKE...) depois de %s." % col["name"])
		return null
	_i += 1
	var value: Variant = _literal_for(col)
	return SqlCompare.new(col, op_token["text"], value) if _error == "" else null


# --- nomes e valores ---

func _resolve_table() -> SqlTable:
	var name := _expect_ident("o nome da tabela")
	if _error != "":
		return null
	for table in _tables:
		if table.name.to_lower() == name.to_lower():
			_table = table
			return table
	_fail("A tabela \"%s\" não existe." % name)
	return null


func _resolve_column(name: String) -> Dictionary:
	if _error != "":
		return {}
	var col := _table.column(name)
	if col.is_empty():
		_fail("A coluna \"%s\" não existe em %s. Colunas: %s." % [name, _table.name, ", ".join(_table.column_names())])
	return col


func _literal_for(col: Dictionary) -> Variant:
	if _error != "":
		return null
	var t := _peek()
	if not t["type"] in ["number", "string"]:
		_fail("Esperava um valor para %s, encontrei \"%s\"." % [col["name"], t["text"]])
		return null
	_i += 1
	_check_literal(col, t)
	return t["value"]


func _check_literal(col: Dictionary, t: Dictionary) -> void:
	match col["type"]:
		"number":
			if t["type"] != "number":
				_fail("%s é um número: escreva sem aspas." % col["name"])
		"text":
			if t["type"] != "string":
				_fail("%s é texto: escreva entre aspas, como 'exemplo'." % col["name"])
		"date":
			var ok: bool = t["type"] == "string" and RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}$").search(t["value"]) != null
			if not ok:
				_fail("%s é uma data: use o formato 'AAAA-MM-DD'." % col["name"])


# --- utilidades ---

func _peek() -> Dictionary:
	return _tokens[mini(_i, _tokens.size() - 1)]


func _accept(type: String, text: String) -> bool:
	if _error == "" and _peek()["type"] == type and _peek()["text"] == text:
		_i += 1
		return true
	return false


func _accept_kw(kw: String) -> bool:
	return _accept("keyword", kw)


func _expect(type: String, text: String) -> void:
	if _error == "" and not _accept(type, text):
		_fail("Esperava \"%s\" %s." % [text, _where_text()])


func _expect_kw(kw: String) -> void:
	_expect("keyword", kw)


func _expect_op(op: String) -> void:
	_expect("op", op)


func _expect_ident(what: String) -> String:
	if _error != "":
		return ""
	var t := _peek()
	if t["type"] != "ident":
		_fail("Esperava %s %s." % [what, _where_text()])
		return ""
	_i += 1
	return t["text"]


func _where_text() -> String:
	var t := _peek()
	return "no fim da consulta" if t["type"] == "eof" else "antes de \"%s\"" % t["text"]


func _fail(message: String) -> void:
	if _error == "":
		_error = message
