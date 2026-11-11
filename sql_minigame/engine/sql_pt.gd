class_name SqlPt
## Gramática do português usada pelos nós da árvore: artigos, contrações e frases
## por operador. Uma coluna pode trocar a frase genérica por uma própria em
## "phrases" no schema (ex.: "que ganham mais de {v}").

const GENERIC: Dictionary = {
	"number": {
		"=": "com {c} igual a {v}", "<>": "com {c} diferente de {v}",
		">": "com {c} maior que {v}", "<": "com {c} menor que {v}",
		">=": "com {c} de {v} ou mais", "<=": "com {c} de até {v}",
	},
	"date": {
		"=": "com {c} em {v}", "<>": "com {c} diferente de {v}",
		">": "com {c} depois de {v}", "<": "com {c} antes de {v}",
		">=": "com {c} a partir de {v}", "<=": "com {c} até {v}",
	},
	"text": {
		"=": "com {c} {v}", "<>": "com {c} diferente de {v}",
		">": "com {c} depois de {v} na ordem alfabética", "<": "com {c} antes de {v} na ordem alfabética",
		">=": "com {c} a partir de {v} na ordem alfabética", "<=": "com {c} até {v} na ordem alfabética",
	},
}


static func article(gender: String, plural: bool) -> String:
	return ("as" if plural else "a") if gender == "f" else ("os" if plural else "o")


## de + artigo: do, da, dos, das
static func de(gender: String, plural: bool) -> String:
	return "d" + article(gender, plural)


## em + artigo: no, na, nos, nas
static func em(gender: String, plural: bool) -> String:
	return "n" + article(gender, plural)


## "o salário", "a data de admissão"
static func with_article(column: Dictionary) -> String:
	return "%s %s" % [article(column["gender"], false), column["pt"]]


## "a", "a e b", "a, b e c"
static func join_list(parts: Array, conjunction: String = "e") -> String:
	if parts.size() <= 1:
		return "" if parts.is_empty() else str(parts[0])
	return ", ".join(parts.slice(0, -1)) + " %s %s" % [conjunction, parts[-1]]


static func sentence(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1) + "."


static func compare_phrase(column: Dictionary, op: String, value: Variant) -> String:
	var template: String = column["phrases"].get(op, GENERIC[column["type"]][op])
	return template.format({"c": column["pt"], "v": SqlLit.to_pt(value)})


## "com setor TI ou RH" — o "ou" fica preso à coluna, sem ambiguidade.
static func in_phrase(column: Dictionary, values: Array) -> String:
	var shown: Array[String] = []
	for v in values:
		shown.append(SqlLit.to_pt(v))
	return "com %s %s" % [column["pt"], join_list(shown, "ou")]


static func between_phrase(column: Dictionary, low: Variant, high: Variant) -> String:
	return "com %s entre %s e %s" % [column["pt"], SqlLit.to_pt(low), SqlLit.to_pt(high)]


static func like_phrase(column: Dictionary, pattern: String) -> String:
	var core := pattern.trim_suffix("%").trim_prefix("%")
	if "%" in core or "_" in core:
		return "com %s no padrão \"%s\"" % [column["pt"], pattern]
	if pattern.begins_with("%") and pattern.ends_with("%"):
		return "com %s contendo \"%s\"" % [column["pt"], core]
	if pattern.ends_with("%"):
		return "com %s começando com \"%s\"" % [column["pt"], core]
	if pattern.begins_with("%"):
		return "com %s terminando com \"%s\"" % [column["pt"], core]
	return "com %s %s" % [column["pt"], pattern]


static func order_phrase(column: Dictionary, desc: bool) -> String:
	var g: String = column["gender"]
	var c: String = column["pt"]
	match column["type"]:
		"number":
			var maior := "maior"
			var menor := "menor"
			return "%s %s %s para %s %s" % [de(g, false), maior if desc else menor, c, article(g, false), menor if desc else maior]
		"date":
			var suffix := "a" if g == "f" else "o"
			var first := "mais recente" if desc else "mais antig" + suffix
			var last := "mais antig" + suffix if desc else "mais recente"
			return "%s %s %s para %s %s" % [de(g, false), c, first, article(g, false), last]
	return "em ordem alfabética %sde %s" % ["inversa " if desc else "", c]


## "só os 3 primeiros" / "só as 3 primeiras"
static func limit_phrase(table: SqlTable, limit: int) -> String:
	if table.gender == "f":
		return "só as %d primeiras" % limit
	return "só os %d primeiros" % limit
