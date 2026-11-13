class_name Tutorial
extends CanvasLayer
## Tutorial do começo do jogo: lições de SQL com lacunas que crescem (uma palavra,
## depois trechos, depois a consulta inteira), sem tempo e sem perder vidas; depois
## um treino de pop-up, um do pet e um do 6-7 (farmar aura). Ao terminar emite `finished` e a GameScene
## começa a partida valendo.
##
## Roda no fácil e na primeira vez que alguém joga (PlayerData.needs_tutorial()).

signal finished
signal _escolha(indice: int)

## Lacunas: `resposta` é o trecho do SQL que o jogador escreve, igual a como ele
## aparece na consulta. Se `resposta` for o SQL inteiro, é a consulta completa.
const LICOES: Array[Dictionary] = [
	{"sql": "SELECT * FROM funcionarios", "resposta": "SELECT",
	 "dica": "Toda consulta que [b]busca[/b] dados começa com [b]SELECT[/b] (selecionar). Escreva SELECT na lacuna e aperte Enter."},
	{"sql": "SELECT * FROM funcionarios", "resposta": "FROM",
	 "dica": "Depois do SELECT vem o que você quer ver ([b]*[/b] quer dizer todas as colunas) e então [b]FROM[/b] (de), seguido do nome da tabela."},
	{"sql": "SELECT * FROM funcionarios", "resposta": "funcionarios",
	 "dica": "O nome da tabela está no painel da esquerda. Comece a digitar e aperte [b]Tab[/b] para completar a sugestão."},
	{"sql": "SELECT nome FROM funcionarios", "resposta": "nome",
	 "dica": "No lugar do [b]*[/b] dá para pedir só uma coluna. As colunas da tabela estão no painel da esquerda."},
	{"sql": "SELECT nome FROM funcionarios WHERE setor = 'TI'", "resposta": "WHERE",
	 "dica": "[b]WHERE[/b] (onde) filtra as linhas: só vêm as que passam na condição escrita depois dele."},
	{"sql": "SELECT nome, salario FROM funcionarios", "resposta": "nome, salario",
	 "dica": "Para ver mais de uma coluna, separe os nomes com vírgula: [b]nome, salario[/b]."},
	{"sql": "SELECT nome FROM funcionarios WHERE setor = 'RH'", "resposta": "setor = 'RH'",
	 "dica": "Uma condição compara uma coluna com um valor. Textos vão entre [b]aspas simples[/b]: setor = 'RH'."},
	{"sql": "SELECT nome FROM funcionarios WHERE salario > 5000", "resposta": "salario > 5000",
	 "dica": "Números vão sem aspas. Para comparar use [b]=[/b], [b]>[/b] (maior), [b]<[/b] (menor), [b]>=[/b] ou [b]<=[/b]."},
	{"sql": "SELECT nome FROM funcionarios WHERE setor = 'TI' AND salario > 4000", "resposta": "AND",
	 "dica": "[b]AND[/b] (e) junta duas condições, e as duas precisam valer. Com [b]OR[/b] (ou), basta uma delas."},
	{"sql": "SELECT nome FROM funcionarios WHERE setor IN ('TI', 'RH')", "resposta": "IN",
	 "dica": "[b]IN[/b] (em) filtra por [b]vários valores[/b] de uma vez: setor IN ('TI', 'RH') traz quem é do TI [b]ou[/b] do RH."},
	{"sql": "SELECT nome FROM funcionarios WHERE setor IN ('Vendas', 'Suporte')", "resposta": "setor IN ('Vendas', 'Suporte')",
	 "dica": "Agora escreva o filtro inteiro: a coluna, [b]IN[/b] e a lista de valores [b]entre parênteses[/b], separados por vírgula. É o mesmo que setor = 'Vendas' OR setor = 'Suporte', só que mais curto."},
	{"sql": "SELECT nome, salario FROM funcionarios ORDER BY salario DESC", "resposta": "ORDER BY salario DESC",
	 "dica": "[b]ORDER BY[/b] ordena o resultado por uma coluna. [b]DESC[/b] vai do maior para o menor; [b]ASC[/b], do menor para o maior."},
	{"sql": "DELETE FROM funcionarios WHERE setor = 'Suporte'", "resposta": "DELETE",
	 "dica": "Nem toda consulta só lê dados. [b]DELETE FROM[/b] apaga as linhas que passam no WHERE."},
	{"sql": "UPDATE funcionarios SET salario = 5000 WHERE nome = 'Ana'", "resposta": "SET",
	 "dica": "[b]UPDATE[/b] muda dados: depois do nome da tabela vem [b]SET[/b] coluna = novo valor."},
	{"sql": "INSERT INTO funcionarios (nome, setor, salario, admissao) VALUES ('Ana', 'TI', 3000, '2024-01-31')", "resposta": "VALUES",
	 "dica": "[b]INSERT INTO[/b] cria uma linha nova: as colunas entre parênteses e, depois de [b]VALUES[/b], os valores na mesma ordem."},
	{"sql": "SELECT nome FROM funcionarios WHERE setor = 'Vendas'", "resposta": "SELECT nome FROM funcionarios WHERE setor = 'Vendas'",
	 "dica": "Agora a consulta inteira! Leia o pedido lá em cima e escreva do SELECT até o fim. O Tab continua ajudando."},
	{"sql": "SELECT nome, salario FROM funcionarios WHERE salario >= 6000 ORDER BY salario DESC", "resposta": "SELECT nome, salario FROM funcionarios WHERE salario >= 6000 ORDER BY salario DESC",
	 "dica": "Última lição: junte o WHERE e o ORDER BY numa consulta só."},
]
## Depois de quantos erros na mesma lição a resposta aparece na dica.
const ERROS_PARA_MOSTRAR_RESPOSTA: int = 2
## Segundos que o pet espera pela carta no treino (no jogo é PetController.feed_window).
const JANELA_DO_PET: float = 20.0

const TEXTO_BOAS_VINDAS: String = """Aqui você vai aprender [b]SQL[/b], a linguagem usada para conversar com bancos de dados.

• Em cima aparece o [b]pedido[/b], em português.
• Logo abaixo, a [b]consulta SQL[/b] com uma lacuna ____ para você completar.
• À esquerda fica a [b]tabela[/b]: o nome dela e as colunas.
• Digite na caixa branca: [b]Tab[/b] completa a sugestão e [b]Enter[/b] envia.

No tutorial não tem tempo nem vidas: pode errar à vontade!"""
const TEXTO_FIM_SQL: String = """Você já sabe o básico de SQL!

Mas o computador do biOS tem suas distrações. Antes de valer pontos, vamos ver as duas que vão atrapalhar você e um jeito de recuperar vidas."""
const TEXTO_POPUPS: String = """Anúncios vão aparecer enquanto você trabalha. Feche cada um clicando na [b]carinha vermelha[/b] antes que ele suma sozinho: se ele sumir, você perde uma [b]vida[/b] (os corações lá em cima).

Alguns andam pela tela e outros se multiplicam quando você clica!

Vamos treinar: feche o pop-up que vai aparecer."""
const TEXTO_POPUP_SUMIU: String = """O pop-up sumiu antes de você fechar. No jogo valendo, isso custaria uma vida.

Tente de novo!"""
const TEXTO_PET: String = """No canto direito mora o [b]Kiki[/b]. De vez em quando ele acorda com fome de e-mails: arraste a [b]carta[/b] da barra de e-mail, lá em cima, até ele antes que o tempo acabe.

Se ele ficar com fome, você perde uma vida.

Vamos acordar o Kiki agora."""
const TEXTO_PET_FOME: String = """O Kiki ficou com fome. No jogo valendo, isso custaria uma vida.

Arraste a carta da barra de e-mail até ele. Vamos tentar de novo!"""
const TEXTO_AURA: String = """A cada 5 respostas certas você pode [b]FARMAR AURA[/b], apertando [b]6[/b] e [b]7[/b] alternadamente, para recuperar uma vida perdida.

Quando a chance aparecer, clique no botão [b]6-7[/b] na barra de baixo (o número mostra quantas chances você tem). Aperte 6, 7, 6, 7... até encher a barra antes que o tempo acabe. Dá para chegar a até 7 vidas.

Vamos treinar: esta chance é por nossa conta!"""
const TEXTO_AURA_FALHOU: String = """O tempo acabou antes de a barra encher. No jogo valendo, essa chance seria perdida.

Tente de novo: 6, 7, 6, 7, bem rápido!"""
const TEXTO_FIM: String = """Agora é para valer: cada acerto dá pontos, as perguntas ficam mais difíceis conforme você joga e, ao perder todas as vidas, o jogo acaba.

Boa sorte!"""

var running: bool = false

var _minigame: Node
var _manager_pop: Node
var _pet: PetController
var _jogo: Node
var _erros: int = 0
var _licao_atual: int = 0

@onready var dialogo: Control = $Dialogo
@onready var titulo: Label = %Titulo
@onready var texto: RichTextLabel = %Texto
@onready var botao_continuar: Button = %Continuar
@onready var botao_pular: Button = %Pular


func _ready() -> void:
	dialogo.hide()


func start(minigame: Node, manager_pop: Node, pet: PetController, jogo: Node) -> void:
	_minigame = minigame
	_manager_pop = manager_pop
	_pet = pet
	_jogo = jogo
	running = true

	var pular := await _dialogo("Bem-vindo ao biOS!", TEXTO_BOAS_VINDAS, "Começar", "Pular tutorial")
	if not pular:
		await _licoes_de_sql()
		await _dialogo("Muito bem!", TEXTO_FIM_SQL, "Continuar")
		await _treino_de_popup()
		await _treino_do_pet()
		await _treino_de_aura()
		await _dialogo("Tudo pronto!", TEXTO_FIM, "Jogar")
	_terminar()


func _terminar() -> void:
	running = false
	PlayerData.finish_tutorial()
	finished.emit()


# --- lições de SQL ---

func _licoes_de_sql() -> void:
	_minigame.resposta_errada.connect(_on_resposta_errada)
	for i in LICOES.size():
		var licao: Dictionary = LICOES[i]
		var pergunta: SqlQuestion = _minigame.pergunta_fixa(licao["sql"], licao["resposta"])
		if pergunta == null:
			push_error("Tutorial: a lição %d não encaixa no SQL: %s" % [i + 1, licao["resposta"]])
			continue
		_erros = 0
		_licao_atual = i
		_mostrar_dica(i)
		_minigame.perguntar(pergunta)
		await _minigame.pergunta_concluida
	_minigame.resposta_errada.disconnect(_on_resposta_errada)
	_minigame.limpar()
	_minigame.esconder_dica()


func _mostrar_dica(i: int) -> void:
	var licao: Dictionary = LICOES[i]
	var bbcode := "[b]Lição %d de %d.[/b] %s" % [i + 1, LICOES.size(), licao["dica"]]
	if _erros >= ERROS_PARA_MOSTRAR_RESPOSTA:
		bbcode += "\n[color=#b71c1c][b]Resposta:[/b][/color] %s" % String(licao["resposta"]).replace("[", "[lb]")
	_minigame.mostrar_dica(bbcode)


func _on_resposta_errada() -> void:
	_erros += 1
	_mostrar_dica(_licao_atual)


# --- pop-ups e pet ---

func _treino_de_popup() -> void:
	await _dialogo("Pop-ups", TEXTO_POPUPS, "Abrir um pop-up")
	while true:
		var popup: BasePop = _manager_pop.spawn_one()
		var fechou := await _primeiro([popup.closed_by_player, popup.expired]) == 0
		if fechou:
			return
		await _dialogo("Quase!", TEXTO_POPUP_SUMIU, "Tentar de novo")


func _treino_do_pet() -> void:
	await _dialogo("O pet", TEXTO_PET, "Acordar o Kiki")
	while true:
		_pet.wake_up(JANELA_DO_PET)
		var alimentou := await _primeiro([_pet.fed, _pet.feeding_missed]) == 0
		_pet.stop()
		if alimentou:
			return
		await _dialogo("Quase!", TEXTO_PET_FOME, "Tentar de novo")


func _treino_de_aura() -> void:
	await _dialogo("Farmar aura", TEXTO_AURA, "Entendi")
	while true:
		_jogo.ganhar_tentativa()
		var sucesso: bool = await _jogo.desafio_6_7_terminou
		if sucesso:
			return
		await _dialogo("Quase!", TEXTO_AURA_FALHOU, "Tentar de novo")


## Espera o primeiro dos sinais (sem argumentos) e devolve o índice dele.
func _primeiro(sinais: Array[Signal]) -> int:
	var ligacoes: Array[Callable] = []
	for i in sinais.size():
		var ao_emitir := func() -> void: _escolha.emit(i)
		sinais[i].connect(ao_emitir)
		ligacoes.append(ao_emitir)
	var indice: int = await _escolha
	for i in sinais.size():
		if not sinais[i].is_null() and sinais[i].is_connected(ligacoes[i]):
			sinais[i].disconnect(ligacoes[i])
	return indice


# --- caixa de diálogo ---

## Mostra a caixa e espera um clique. Devolve true se o botão secundário
## (`secundario`, só aparece se não for vazio) foi o escolhido.
func _dialogo(p_titulo: String, bbcode: String, principal: String, secundario: String = "") -> bool:
	titulo.text = p_titulo
	texto.text = bbcode
	botao_continuar.text = principal
	botao_pular.text = secundario
	botao_pular.visible = secundario != ""
	dialogo.show()
	botao_continuar.grab_focus()
	var escolhido := await _primeiro([botao_continuar.pressed, botao_pular.pressed])
	dialogo.hide()
	return escolhido == 1
