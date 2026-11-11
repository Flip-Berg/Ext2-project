extends Control

# O símbolo @onready faz o Godot "pegar" os nós da nossa interface assim que o jogo começa
@onready var texto_objetivo = $TextoObjetivo
@onready var entrada_jogador = $EntradaJogador

# Uma lista simples de queries para o jogador digitar
var lista_de_queries = [
	"SELECT * FROM usuarios",
	"DELETE FROM logs",
	"UPDATE produtos",
	"INSERT INTO clientes"
]

# Variável para guardar qual é a query que o jogador precisa digitar agora
var query_atual = ""

# A função _ready() roda automaticamente UMA VEZ assim que o jogo começa
func _ready():
	nova_query() # Puxa uma query aleatória no começo do jogo
	
	# Aqui nós conectamos a tecla "Enter". 
	# Quando o jogador apertar Enter no LineEdit, ele vai chamar a função _checar_resposta
	entrada_jogador.text_submitted.connect(_checar_resposta)

# Função para sortear uma nova query e mostrar na tela
func nova_query():
	# Pega uma frase aleatória da nossa lista
	query_atual = lista_de_queries.pick_random() 
	
	# Muda o texto do Label da tela para a query sorteada
	texto_objetivo.text = "Digite o código: " + query_atual
	
	# Limpa o que o jogador digitou antes
	entrada_jogador.text = "" 
	
	# Faz o cursor do teclado já ficar piscando no campo de texto, sem ele precisar clicar
	entrada_jogador.grab_focus()

# Função que verifica se o jogador acertou
func _checar_resposta(texto_digitado):
	# O strip_edges() tira espaços em branco no começo ou fim que o jogador digitou sem querer
	if texto_digitado.strip_edges() == query_atual:
		print("VOCÊ ACERTOU! Ganhou pontos.") # Aparece no console do Godot
		nova_query() # Gera a próxima query automaticamente
	else:
		print("VOCÊ ERROU!")
		entrada_jogador.text = "" # Limpa o texto para ele tentar de novo
