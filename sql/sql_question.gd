class_name SqlQuestion
extends RefCounted
## Uma pergunta pronta: a árvore, o pedido em português e a lacuna a preencher.
## A resposta do jogador é encaixada na lacuna e o SQL inteiro vai para o SqlChecker,
## então lacunas de qualquer tamanho são conferidas do mesmo jeito.

enum Mode {
	KEYWORD, ## uma palavra-chave (FROM, WHERE, ...)
	PIECE,   ## uma coluna, operador ou valor
	CLAUSE,  ## o WHERE inteiro (ou o VALUES do INSERT)
	FULL,    ## a consulta inteira
}

const BLANK: String = "____"
const BASE_TIME: float = 10.0
const TIME_PER_COST: float = 4.0
const EXTRA_TIME: Dictionary = {Mode.KEYWORD: 0.0, Mode.PIECE: 0.0, Mode.CLAUSE: 6.0, Mode.FULL: 12.0}
const LONG_COST: int = 8

var tree: SqlStatement
var table: SqlTable
var prompt: String
var mode: Mode
var tokens: Array[Dictionary]
var blank_start: int
var blank_end: int  # exclusivo
var time_limit: float


static func create(p_tree: SqlStatement, p_mode: Mode, rng: RandomNumberGenerator) -> SqlQuestion:
	var q := SqlQuestion.new()
	q.tree = p_tree
	q.table = p_tree.table
	q.prompt = p_tree.to_pt(p_tree.table)
	q.tokens = p_tree.to_tokens()
	q.mode = p_mode
	q._pick_blank(rng)
	q.time_limit = BASE_TIME + TIME_PER_COST * p_tree.cost() + EXTRA_TIME[q.mode]
	return q


## SQL mostrado na tela, com a lacuna.
func shown_sql() -> String:
	if mode == Mode.FULL:
		return ""
	var shown := tokens.slice(0, blank_start)
	shown.append({"text": BLANK, "role": SqlNode.PUNCT})
	shown.append_array(tokens.slice(blank_end))
	return SqlNode.join_tokens(shown)


func prefix_text() -> String:
	return SqlNode.join_tokens(tokens.slice(0, blank_start))


func suffix_text() -> String:
	return SqlNode.join_tokens(tokens.slice(blank_end))


## O que deveria ir na lacuna.
func answer_text() -> String:
	return SqlNode.join_tokens(tokens.slice(blank_start, blank_end))


## SQL completo com o texto do jogador na lacuna.
func full_answer(player_text: String) -> String:
	return "%s %s %s" % [prefix_text(), player_text, suffix_text()]


## Perguntas longas aliviam os pop-ups (ver DifficultyDirector).
func is_long() -> bool:
	return mode == Mode.FULL or tree.cost() >= LONG_COST


func _pick_blank(rng: RandomNumberGenerator) -> void:
	if mode == Mode.CLAUSE and not _pick_clause():
		mode = Mode.PIECE
	match mode:
		Mode.FULL:
			blank_start = 0
			blank_end = tokens.size()
		Mode.KEYWORD:
			_pick_token([SqlNode.KEYWORD], rng)
		Mode.PIECE:
			_pick_token([SqlNode.COLUMN, SqlNode.OPERATOR, SqlNode.VALUE, SqlNode.TABLE], rng)


func _pick_token(roles: Array, rng: RandomNumberGenerator) -> void:
	var candidates := []
	for i in tokens.size():
		if tokens[i]["role"] in roles:
			candidates.append(i)
	blank_start = candidates[rng.randi_range(0, candidates.size() - 1)]
	blank_end = blank_start + 1


func _pick_clause() -> bool:
	for i in tokens.size():
		if tokens[i]["text"] in ["WHERE", "VALUES"] and tokens[i]["role"] == SqlNode.KEYWORD:
			blank_start = i
			blank_end = tokens.size()
			for j in range(i + 1, tokens.size()):
				if tokens[j]["text"] in ["ORDER BY", "LIMIT"]:
					blank_end = j
					break
			return true
	return false
