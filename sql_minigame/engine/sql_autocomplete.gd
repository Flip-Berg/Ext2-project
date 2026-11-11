class_name SqlAutocomplete
## Sugestões para o campo de resposta, a partir do que já está escrito antes do cursor.
## Segue a gramática do SqlParser: olha o último token (e a cláusula em que ele está)
## e sugere só o que pode vir em seguida — palavras-chave, a tabela ou colunas.
## Onde se espera um valor (número, texto, data) não sugere nada.

## O que já foi escrito: comando (SELECT, UPDATE...), cláusula atual e os tokens
## classificados como {"kind": "keyword"|"table"|"column"|"value"|"op"|"punct", "text"}.
const CLAUSES: Array[String] = ["SELECT", "FROM", "WHERE", "ORDER", "LIMIT", "UPDATE", "SET", "DELETE", "INSERT", "INTO", "VALUES"]
const STATEMENTS: Array[String] = ["SELECT", "UPDATE", "DELETE", "INSERT"]


## Devolve [{"text", "kind": "keyword"|"table"|"column"}], já filtrado pelo prefixo digitado.
static func suggestions(text_before_caret: String, table: SqlTable) -> Array[Dictionary]:
	var prefix := _current_word(text_before_caret)
	var before := text_before_caret.left(text_before_caret.length() - prefix.length())
	var tokens := _classify(before, table)
	# Onde a consulta já pode terminar, a lista só abre depois da primeira letra:
	# senão um espaço no fim abriria a lista e o Enter escolheria AND em vez de enviar.
	if prefix == "" and _can_end_here(tokens):
		return []
	var options: Array = _expected(tokens, table)

	var lower := prefix.to_lower()
	var matching := options.filter(func(o: Dictionary) -> bool:
		return o["text"].to_lower().begins_with(lower))
	# Uma palavra já completa só continua na lista se houver outra mais longa com o
	# mesmo começo (OR / ORDER BY); assim Enter no fim da consulta envia em vez de
	# "completar" DESC com DESC.
	if matching.size() == 1 and matching[0]["text"].to_lower() == lower:
		matching.clear()
	var out: Array[Dictionary] = []
	out.assign(matching)
	return out


static func _expected(tokens: Array[Dictionary], table: SqlTable) -> Array[Dictionary]:
	var columns: Array[Dictionary] = []
	for c in table.column_names():
		columns.append({"text": c, "kind": "column"})
	var tabela: Array[Dictionary] = [{"text": table.name, "kind": "table"}]

	if tokens.is_empty():
		return _kw(STATEMENTS)

	var statement: String = tokens[0]["text"]
	var clause := statement
	for t in tokens:
		if t["kind"] == "keyword" and t["text"] in CLAUSES:
			clause = t["text"]
	var last: Dictionary = tokens[-1]
	var prev: Dictionary = tokens[-2] if tokens.size() > 1 else {}
	var l: String = last["text"]

	match last["kind"]:
		"keyword":
			match l:
				"SELECT", "BY", "SET":
					return columns
				"WHERE", "AND", "OR":
					if l == "AND" and _inside_between(tokens):
						return []
					return _join(columns, _kw(["NOT"]))
				"NOT":
					if prev.get("kind") == "column":
						return _kw(["IN"])
					return columns
				"FROM", "UPDATE", "INTO":
					return tabela
				"DELETE":
					return _kw(["FROM"])
				"INSERT":
					return _kw(["INTO"])
				"ORDER":
					return _kw(["BY"])
				"ASC", "DESC":
					return _kw(["LIMIT"])
			return []  # IN, BETWEEN, LIKE, LIMIT, VALUES: vem um valor ou "("
		"table":
			match statement:
				"SELECT": return _kw(["WHERE", "ORDER BY", "LIMIT"])
				"DELETE": return _kw(["WHERE"])
				"UPDATE": return _kw(["SET"])
				"INSERT": return _kw(["VALUES"])
		"column":
			match clause:
				"SELECT": return _kw(["FROM"])
				"WHERE": return _kw(["NOT", "IN", "BETWEEN", "LIKE"])
				"ORDER": return _kw(["ASC", "DESC", "LIMIT"])
			return []  # SET coluna =, INSERT (colunas)
		"value":
			return _after_value(tokens, statement, clause)
		"punct":
			match l:
				",":
					return columns if clause in ["SELECT", "SET", "ORDER", "INTO"] else []
				"(":
					if clause == "WHERE" and prev.get("text") not in ["IN"]:
						return _join(columns, _kw(["NOT"]))
					if clause == "INTO":
						return columns
				")":
					if clause == "INTO":
						return _kw(["VALUES"])
					if clause == "WHERE":
						return _after_value(tokens, statement, clause)
	return []


static func _after_value(tokens: Array[Dictionary], statement: String, clause: String) -> Array[Dictionary]:
	if clause == "WHERE":
		if tokens.size() > 1 and tokens[-2]["text"] == "BETWEEN":
			return _kw(["AND"])
		var options := _kw(["AND", "OR"])
		if statement == "SELECT":
			options = _join(options, _kw(["ORDER BY", "LIMIT"]))
		return options
	if clause == "SET":
		return _kw(["WHERE"])
	return []


## Se a consulta escrita até aqui já pode estar completa.
static func _can_end_here(tokens: Array[Dictionary]) -> bool:
	if tokens.is_empty():
		return false
	var statement: String = tokens[0]["text"]
	var clause := statement
	for t in tokens:
		if t["kind"] == "keyword" and t["text"] in CLAUSES:
			clause = t["text"]
	var last: Dictionary = tokens[-1]
	match last["kind"]:
		"table":
			return statement in ["SELECT", "DELETE"]
		"column":
			return clause == "ORDER"
		"keyword":
			return last["text"] in ["ASC", "DESC"]
		"value":
			return not (tokens.size() > 1 and tokens[-2]["text"] == "BETWEEN")
		"punct":
			return last["text"] == ")"
	return false


## "x BETWEEN 1 AND |": o AND faz parte do BETWEEN, então vem um valor.
static func _inside_between(tokens: Array[Dictionary]) -> bool:
	return tokens.size() >= 3 and tokens[-3]["text"] == "BETWEEN"


static func _kw(words: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w in words:
		out.append({"text": w, "kind": "keyword"})
	return out


static func _current_word(text: String) -> String:
	var i := text.length()
	while i > 0 and SqlTokenizer._is_word_char(text[i - 1]):
		i -= 1
	return text.substr(i)


## Tokens já escritos, com palavras reconhecidas como tabela/coluna. Texto com aspas
## abertas para o tokenizador no meio; o que veio antes ainda serve de contexto.
static func _classify(text: String, table: SqlTable) -> Array[Dictionary]:
	var tokenizer := SqlTokenizer.new()
	var columns := table.column_names().map(func(c: String) -> String: return c.to_lower())
	var out: Array[Dictionary] = []
	for t in tokenizer.tokenize(text):
		var kind: String = t["type"]
		var word: String = t["text"]
		match kind:
			"eof":
				continue
			"ident":
				if word.to_lower() == table.name.to_lower():
					kind = "table"
				elif word.to_lower() in columns:
					kind = "column"
				else:
					kind = "value"
			"number", "string":
				kind = "value"
			"punct":
				if word == "*":
					kind = "column"
		out.append({"kind": kind, "text": word})
	return out


static func _join(a: Array[Dictionary], b: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = a.duplicate()
	out.append_array(b)
	return out
