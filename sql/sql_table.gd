class_name SqlTable
extends RefCounted
## Uma tabela "falsa", descrita num arquivo JSON em res://sql/schemas/.
## Não existe banco de dados: as linhas são geradas por SqlFakeRows quando preciso.
##
## Cada coluna é um Dictionary com:
##   name      nome em SQL (ASCII, snake_case)
##   type      "number", "text" ou "date" (datas no formato 'AAAA-MM-DD')
##   pt        nome em português ("data de admissão"); gender "m"/"f"
##   values    (text) valores possíveis
##   min/max   (number/date) faixa; step (number) passo entre valores
##   like      (text) pode aparecer em LIKE; editable: pode ser alvo de UPDATE
##   phrases   (opcional) frases por operador, ex.: {">": "que ganham mais de {v}"}

const SCHEMA_DIR: String = "res://sql/schemas"

var name: String
var singular: String
var plural: String
var gender: String = "m"
var columns: Array[Dictionary] = []


static func load_all(dir: String = SCHEMA_DIR) -> Array[SqlTable]:
	var tables: Array[SqlTable] = []
	for file_name in DirAccess.get_files_at(dir):
		if not file_name.ends_with(".json"):
			continue
		var table := SqlTable.from_file(dir.path_join(file_name))
		if table != null:
			tables.append(table)
	return tables


static func from_file(path: String) -> SqlTable:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_error("Schema SQL inválido: %s" % path)
		return null
	var table := SqlTable.new()
	table.name = data["table"]
	table.singular = data["singular"]
	table.plural = data["plural"]
	table.gender = data.get("gender", "m")
	for raw in data["columns"]:
		var col: Dictionary = raw.duplicate(true)
		col["gender"] = col.get("gender", "m")
		col["phrases"] = col.get("phrases", {})
		# JSON só tem float; números da tabela são inteiros.
		for key in ["min", "max", "step"]:
			if col.has(key) and col[key] is float:
				col[key] = int(col[key])
		table.columns.append(col)
	return table


## Coluna pelo nome (sem diferenciar maiúsculas), ou {} se não existir.
func column(column_name: String) -> Dictionary:
	for col in columns:
		if col["name"].to_lower() == column_name.to_lower():
			return col
	return {}


func column_names() -> Array[String]:
	var names: Array[String] = []
	for col in columns:
		names.append(col["name"])
	return names
