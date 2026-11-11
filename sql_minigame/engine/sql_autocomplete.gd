class_name SqlAutocomplete
## Sugestões para o campo de resposta, a partir do que já está escrito antes do cursor.
## Nomes de tabela e coluna são sempre sugeridos (decorar nomes não é o desafio);
## palavras-chave só quando `with_keywords` (dificuldade baixa).

const AFTER_TABLE: Array[String] = ["FROM", "UPDATE", "INTO"]
const AFTER_COLUMN: Array[String] = ["SELECT", ",", "WHERE", "AND", "OR", "BY", "SET", "NOT", "("]


## Devolve [{"text", "kind": "keyword"|"table"|"column"}], já filtrado pelo prefixo digitado.
static func suggestions(text_before_caret: String, table: SqlTable, with_keywords: bool) -> Array[Dictionary]:
	var prefix := _current_word(text_before_caret)
	var before := text_before_caret.left(text_before_caret.length() - prefix.length())
	var previous := _previous_tokens(before)
	var last := previous[-1] if previous.size() > 0 else ""
	var before_last := previous[-2] if previous.size() > 1 else ""

	var options: Array[Dictionary] = []
	if last in AFTER_TABLE:
		options.append({"text": table.name, "kind": "table"})
	elif last in AFTER_COLUMN and not (last == "(" and before_last in ["VALUES", "IN"]):
		for c in table.column_names():
			options.append({"text": c, "kind": "column"})
	elif with_keywords and prefix != "":
		for kw in SqlTokenizer.KEYWORDS:
			options.append({"text": kw, "kind": "keyword"})

	var lower := prefix.to_lower()
	return options.filter(func(o: Dictionary) -> bool:
		return o["text"].to_lower().begins_with(lower) and o["text"].to_lower() != lower)


static func _current_word(text: String) -> String:
	var i := text.length()
	while i > 0 and SqlTokenizer._is_word_char(text[i - 1]):
		i -= 1
	return text.substr(i)


## Os últimos tokens (palavras em maiúsculas e símbolos), ignorando textos entre aspas.
static func _previous_tokens(text: String) -> Array[String]:
	var tokenizer := SqlTokenizer.new()
	var tokens := tokenizer.tokenize(text)
	var out: Array[String] = []
	for t in tokens:
		if t["type"] == "eof":
			continue
		out.append(t["text"].to_upper() if t["type"] in ["keyword", "ident"] else t["text"])
	return out
