extends Control

# Puxando nossos nós da interface
@onready var texto_objetivo = $TextoObjetivo # A query com a lacuna
@onready var entrada_jogador = $EntradaJogador
@onready var label_pseudocodigo = $LabelPseudocodigo
@onready var barra_tempo = $BarraTempo
@onready var fundo_feedback = $FundoFeedback # O ColorRect que criamos

# 5. MAIOR VARIABILIDADE E 4. PSEUDOCÓDIGO / 2. PREENCHA A LACUNA
# Usamos um Dicionário de arrays para guardar todas as informações de cada rodada
var banco_queries = [
	{"pseudo": "-> Busque todos os dados da tabela usuários", "exibicao": "SELECT * ____ usuarios", "resposta": "FROM"},
	{"pseudo": "-> Selecione apenas a coluna nome", "exibicao": "______ nome FROM clientes", "resposta": "SELECT"},
	{"pseudo": "-> Atualize o registro de produtos", "exibicao": "______ produtos SET preco = 10", "resposta": "UPDATE"},
	{"pseudo": "-> Delete os logs antigos", "exibicao": "DELETE FROM logs ______ data < 2023", "resposta": "WHERE"},
	{"pseudo": "-> Insira um novo cliente", "exibicao": "INSERT ______ clientes VALUES ('Joao')", "resposta": "INTO"},
	{"pseudo": "-> Defina o valor de status para ativo", "exibicao": "UPDATE usuarios ______ status = 'ativo'", "resposta": "SET"}
]

var query_atual = {}

# 6. TIMER E DIFICULDADE
var tempo_maximo = 30.0 # O jogador começa tendo 10 segundos para responder
var tempo_restante = 30.0
var multiplicador_dificuldade = 1.0 # Vai aumentar para fazer o tempo passar mais rápido

func _ready():
	entrada_jogador.text_submitted.connect(_checar_resposta)
	fundo_feedback.modulate.a = 0 # Garante que o fundo de feedback está invisível
	nova_query()

# Esta função roda o tempo todo (60 vezes por segundo)
func _process(delta):
	# Diminui o tempo restante (delta é o tempo entre os frames)
	tempo_restante -= delta 
	
	# Atualiza a barrinha visual (de 0 a 100)
	barra_tempo.value = (tempo_restante / (tempo_maximo / multiplicador_dificuldade)) * 100
	
	# Se o tempo zerar
	if tempo_restante <= 0:
		_erro_por_tempo()

func nova_query():
	query_atual = banco_queries.pick_random()
	
	label_pseudocodigo.text = query_atual["pseudo"]
	texto_objetivo.text = query_atual["exibicao"]
	
	entrada_jogador.text = ""
	entrada_jogador.grab_focus()
	
	# Reseta o tempo, dividindo pela dificuldade (ex: se dificuldade for 2.0, o tempo cai pra 5s)
	tempo_restante = tempo_maximo / multiplicador_dificuldade

func _checar_resposta(texto_digitado):
	# O to_upper() faz o jogo aceitar tanto "from" minúsculo quanto "FROM" maiúsculo!
	if texto_digitado.strip_edges().to_upper() == query_atual["resposta"].to_upper():
		_acertou()
	else:
		_errou()

# 1. FEEDBACK VISUAL
func _acertou():
	multiplicador_dificuldade = min(multiplicador_dificuldade + 0.05, 1.5) # Aumenta a dificuldade (tempo mais rápido!)
	_piscar_tela(Color.GREEN)
	nova_query()
	
func _errou():
	_piscar_tela(Color.RED)
	entrada_jogador.text = "" # Limpa a barra para ele tentar de novo
	entrada_jogador.grab_focus() # FORÇA O CURSOR A VOLTAR PARA A BARRA

func _erro_por_tempo():
	_piscar_tela(Color.DARK_RED)
	# Aqui no futuro nós vamos colocar o código para perder 1 vida!
	multiplicador_dificuldade = max(1.0, multiplicador_dificuldade - 0.2) # Facilita um pouco já que ele perdeu
	nova_query()

# Função que usa 'Tween' para criar uma animação suave do fundo piscando e sumindo
func _piscar_tela(cor: Color):
	fundo_feedback.color = cor
	fundo_feedback.modulate.a = 0.4 # Fica 40% visível
	
	# Cria uma animação que faz a transparência (Alpha) ir para 0 em meio segundo
	var tween = create_tween()
	tween.tween_property(fundo_feedback, "modulate:a", 0.0, 0.5)
