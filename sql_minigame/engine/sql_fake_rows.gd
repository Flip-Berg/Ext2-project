class_name SqlFakeRows
## Gera linhas falsas a partir do schema: é o "banco de dados" do jogo.
## Valores logo antes, em cima e logo depois de cada literal das consultas são
## espalhados nas linhas, para que ">=" no lugar de ">" dê resultado diferente.

const DAY: int = 86400


static func make(table: SqlTable, literals: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var rows := []
	for i in count:
		var row := {"_id": i}
		for col in table.columns:
			row[col["name"]] = random_value(col, rng)
		rows.append(row)
	for pair in literals:
		var col: Dictionary = pair[0]
		for v in near_values(col, pair[1]):
			rows[rng.randi_range(0, count - 1)][col["name"]] = v
	return rows


static func random_value(col: Dictionary, rng: RandomNumberGenerator) -> Variant:
	match col["type"]:
		"number":
			var step: int = col.get("step", 1)
			return rng.randi_range(int(col["min"] / step), int(col["max"] / step)) * step
		"date":
			var low := Time.get_unix_time_from_datetime_string(col["min"])
			var high := Time.get_unix_time_from_datetime_string(col["max"])
			return day_string(low + rng.randi_range(0, int((high - low) / DAY)) * DAY)
	return col["values"][rng.randi_range(0, col["values"].size() - 1)]


static func near_values(col: Dictionary, value: Variant) -> Array:
	match col["type"]:
		"number":
			if SqlLit.is_number(value):
				var step: int = col.get("step", 1)
				return [value - step, value, value + step]
		"date":
			if value is String and value.length() == 10:
				var t := Time.get_unix_time_from_datetime_string(value)
				return [day_string(t - DAY), value, day_string(t + DAY)]
		"text":
			if value is String and value != "":
				return [value, value + "x"]
	return []


static func day_string(unix_time: int) -> String:
	return Time.get_datetime_string_from_unix_time(unix_time).left(10)
