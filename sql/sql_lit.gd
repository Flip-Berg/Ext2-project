class_name SqlLit
## Funções para valores literais. Números são int/float; textos e datas são String
## (datas no formato 'AAAA-MM-DD', que ordena corretamente como texto).
## Comparações de texto ignoram maiúsculas/minúsculas, para não punir 'ti' vs 'TI'.


static func is_number(value: Variant) -> bool:
	return value is int or value is float


## Como o valor aparece em SQL: 3000, 'TI', '2020-05-01'.
static func to_sql(value: Variant) -> String:
	if value is String:
		return "'%s'" % value.replace("'", "''")
	return _number_text(value)


## Como o valor aparece no texto em português (sem aspas).
static func to_pt(value: Variant) -> String:
	if value is String:
		return value
	return _number_text(value)


## Forma normalizada, usada para comparar resultados e árvores.
static func key(value: Variant) -> String:
	if value is String:
		return "'%s'" % value.to_lower()
	return _number_text(value)


## -1, 0 ou 1.
static func compare(a: Variant, b: Variant) -> int:
	if is_number(a) and is_number(b):
		return signi(int(signf(float(a) - float(b))))
	return str(a).nocasecmp_to(str(b))


static func _number_text(value: Variant) -> String:
	if value is float and is_equal_approx(value, roundf(value)):
		return str(int(value))
	return str(value)
