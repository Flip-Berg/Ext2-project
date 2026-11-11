class_name SqlTokenizer
extends RefCounted
## Quebra o SQL digitado em tokens:
## {"type": "keyword"|"ident"|"number"|"string"|"op"|"punct"|"eof", "text", "value", "pos"}

const KEYWORDS: Array[String] = [
	"SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "BETWEEN", "LIKE", "ORDER", "BY",
	"ASC", "DESC", "LIMIT", "UPDATE", "SET", "DELETE", "INSERT", "INTO", "VALUES",
]

var error: String = ""


func tokenize(text: String) -> Array[Dictionary]:
	error = ""
	var tokens: Array[Dictionary] = []
	var i := 0
	var n := text.length()
	while i < n:
		var ch := text[i]
		if ch in " \t\r\n":
			i += 1
		elif _is_word_char(ch) and not ch.is_valid_int():
			var j := i
			while j < n and _is_word_char(text[j]):
				j += 1
			var word := text.substr(i, j - i)
			var upper := word.to_upper()
			if upper in KEYWORDS:
				tokens.append({"type": "keyword", "text": upper, "pos": i})
			else:
				tokens.append({"type": "ident", "text": word, "pos": i})
			i = j
		elif ch.is_valid_int() or (ch == "-" and i + 1 < n and text[i + 1].is_valid_int()):
			var j := i + 1
			while j < n and (text[j].is_valid_int() or text[j] == "."):
				j += 1
			var number := text.substr(i, j - i)
			if not number.is_valid_float():
				error = "Número inválido: %s" % number
				return tokens
			var value: Variant = number.to_int() if number.is_valid_int() else number.to_float()
			tokens.append({"type": "number", "text": number, "value": value, "pos": i})
			i = j
		elif ch == "'" or ch == "\"":
			var j := i + 1
			var value := ""
			var closed := false
			while j < n:
				if text[j] == ch:
					if ch == "'" and j + 1 < n and text[j + 1] == "'":  # '' dentro de '...'
						value += "'"
						j += 2
						continue
					closed = true
					break
				value += text[j]
				j += 1
			if not closed:
				error = "Faltou fechar as aspas do texto %s%s" % [ch, value]
				return tokens
			tokens.append({"type": "string", "text": text.substr(i, j - i + 1), "value": value, "pos": i})
			i = j + 1
		elif i + 1 < n and text.substr(i, 2) in ["<=", ">=", "<>", "!="]:
			var op := text.substr(i, 2)
			tokens.append({"type": "op", "text": "<>" if op == "!=" else op, "pos": i})
			i += 2
		elif ch in "=<>":
			tokens.append({"type": "op", "text": ch, "pos": i})
			i += 1
		elif ch in ",()*;":
			tokens.append({"type": "punct", "text": ch, "pos": i})
			i += 1
		else:
			error = "Caractere inesperado: %s" % ch
			return tokens
	tokens.append({"type": "eof", "text": "", "pos": n})
	return tokens


## Letras (inclusive acentuadas, para dar um erro claro em "salário"), dígitos e _.
static func _is_word_char(ch: String) -> bool:
	return ch == "_" or ch.is_valid_int() or ch.to_upper() != ch.to_lower()
