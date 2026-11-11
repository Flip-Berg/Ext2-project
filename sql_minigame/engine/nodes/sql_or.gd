class_name SqlOr
extends SqlCondition
## c1 OR c2 OR ...
## A primeira versão só GERA "OU" dentro de uma coluna (como SqlInList), mas o jogador
## pode escrever OR à vontade: "setor = 'TI' OR setor = 'RH'" é normalizado para IN.

var children: Array[SqlCondition] = []


func _init(p_children: Array[SqlCondition]) -> void:
	for child in p_children:
		if child is SqlOr:
			children.append_array(child.children)
		else:
			children.append(child)


func matches(row: Dictionary) -> bool:
	for child in children:
		if child.matches(row):
			return true
	return false


func to_tokens() -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	for i in children.size():
		if i > 0:
			tokens.append(tok("OR", KEYWORD))
		var child_tokens := children[i].to_tokens()
		if children[i] is SqlAnd:
			tokens.append(tok("(", PUNCT))
			tokens.append_array(child_tokens)
			tokens.append(tok(")", PUNCT))
		else:
			tokens.append_array(child_tokens)
	return tokens


func to_pt(table: SqlTable) -> String:
	var same := as_in_list()
	if same != null:
		return same.to_pt(table)
	# Camada 2 do design (OR entre colunas): uma lista de "pelo menos uma".
	var parts: Array[String] = []
	for child in children:
		parts.append(child.to_pt(table))
	return "que atendam a pelo menos uma destas condições: " + "; ".join(parts)


func cost() -> int:
	var total := 1
	for child in children:
		total += child.cost()
	return total


func canonical() -> String:
	var same := as_in_list()
	if same != null:
		return same.canonical()
	var parts: Array[String] = []
	for child in children:
		var c := child.canonical()
		parts.append("(%s)" % c if " AND " in c else c)
	parts.sort()
	return " OR ".join(parts)


func literals() -> Array:
	var out := []
	for child in children:
		out.append_array(child.literals())
	return out


## Se todos os filhos são "mesma_coluna = valor" (ou IN), devolve o IN equivalente.
func as_in_list() -> SqlInList:
	var column_name := ""
	var column: Dictionary = {}
	var values := []
	for child in children:
		if child is SqlCompare and child.op == "=":
			values.append(child.value)
		elif child is SqlInList:
			values.append_array(child.values)
		else:
			return null
		if column_name == "":
			column_name = child.column["name"]
			column = child.column
		elif child.column["name"] != column_name:
			return null
	return SqlInList.new(column, values)
