class_name SqlNode
extends RefCounted
## Base de todos os nós da árvore de consulta.
##
## Para adicionar um recurso de SQL: crie uma subclasse que implemente as funções
## abaixo e adicione um ramo em SqlGenerator (gerar) e SqlParser (ler do jogador).
## Condições estendem SqlCondition (matches); comandos estendem SqlStatement (execute).

# Papel de cada token na renderização SQL: decide o que pode virar lacuna
# e que tipo de palavra o autocomplete sugere.
const KEYWORD: String = "keyword"
const TABLE: String = "table"
const COLUMN: String = "column"
const OPERATOR: String = "operator"
const VALUE: String = "value"
const PUNCT: String = "punct"


## SQL como lista de tokens {"text", "role"}.
func to_tokens() -> Array[Dictionary]:
	return []


## Texto em português (pedido ao jogador).
func to_pt(_table: SqlTable) -> String:
	return ""


## Custo de dificuldade (o gerador gasta um orçamento nesses pontos).
func cost() -> int:
	return 0


## Forma normalizada: duas árvores equivalentes "óbvias" dão o mesmo texto.
func canonical() -> String:
	return ""


## Pares [coluna, valor] usados na árvore (para gerar linhas falsas perto deles).
func literals() -> Array:
	return []


func to_sql() -> String:
	return join_tokens(to_tokens())


static func tok(text: String, role: String) -> Dictionary:
	return {"text": text, "role": role}


static func join_tokens(tokens: Array) -> String:
	var out := ""
	for i in tokens.size():
		var text: String = tokens[i]["text"]
		if i > 0 and not text in [",", ")"] and tokens[i - 1]["text"] != "(":
			out += " "
		out += text
	return out
