# Main.gd
extends Node2D

# Cenas Exportadas
@export var cena_peca: PackedScene         # Cena da peça
@export var cena_botao_ui: PackedScene     # Cena do botão de interface
@export var cena_padrao_corte: PackedScene # Cena para exibir padrões salvos

# Referências de Nós (@onready)
@onready var retangulo_container: ColorRect = $Container
@onready var pai_pecas: Node2D = $RectanglesParent
@onready var rotulo_feedback: Label = $UI/FeedbackLabel
@onready var vbox_pecas_disponiveis: VBoxContainer = $UI/AvailablePiecesVBox
@onready var vbox_padroes_salvos: VBoxContainer = $UI/PadraoCorteSalvo

# Variáveis
var largura_container: float
var largura_total_atual: float = 0.0
var pecas_encaixadas: Array[PieceScript] = []
var botao_visivel: bool
var padroes_corte_salvos: Array = []

# Dados das Peças
var pecas_disponiveis: Array = [
	{"nome": "Adaga (P)", "largura": 110.0, "comprimento": 50.0, "caminho_textura": "res://Sprite/adaga.png"},
	{"nome": "Espada L (M)", "largura": 150.0, "comprimento": 50.0, "caminho_textura": "res://Sprite/Esp_Larg.png"},
	{"nome": "Espada G (L)", "largura": 180.0, "comprimento": 50.0, "caminho_textura": "res://Sprite/Esp_Grande.png"},
]

func _ready():
	add_to_group("main_logic")
	
	botao_visivel = false
	retangulo_container.size.x = 498
	retangulo_container.size.y = 50
	largura_container = retangulo_container.size.x
	retangulo_container.color = Color.WHITE
	retangulo_container.position = Vector2(300, 100)
	
	_configurar_botoes_ui()
	_reiniciar_jogo()

func _on_padraocorte_salvo_pressed():
	if largura_total_atual == 0:
		_atualizar_texto_resultado("Não há peças encaixadas para salvar!")
		return

	# Cria o dicionário de dados do padrão
	var dados_padrao = {
		"largura": largura_total_atual,
		"eficiencia": (largura_total_atual / largura_container) * 100.0,
		"pecas": [],
		"nome": "Padrão %d" % (padroes_corte_salvos.size() + 1)
	}
	for peca in pecas_encaixadas:
		dados_padrao.pecas.append({
			"largura_peca": peca.largura_peca, 
			"caminho_textura": peca.caminho_textura 
		})
	padroes_corte_salvos.append(dados_padrao)
	#Exibe o novo padrão
	_exibir_padrao_salvo(dados_padrao)
	_atualizar_texto_resultado("Padrão '%s' salvo com sucesso!" % dados_padrao.nome)

func _exibir_padrao_salvo(dados: Dictionary):
	if not is_instance_valid(cena_padrao_corte):
		print("ERRO: cena_padrao_corte não está ligada no Inspector.")
		return

	#Instancia a cena de exibição
	var no_padrao_corte: Control = cena_padrao_corte.instantiate()
	no_padrao_corte.name = dados.nome
	
	#Localiza nós filhos
	var rotulo_nome: Label = no_padrao_corte.get_node("PatternLabel")
	var visualizador_container: HBoxContainer = no_padrao_corte.get_node("PatternVisualizer")
	var fundo_branco: ColorRect = no_padrao_corte.get_node("BackGround")
	
	rotulo_nome.text = "%s (Eficiência: %.2f%%)" % [dados.nome, dados.eficiencia]	
	rotulo_nome.position.x = retangulo_container.size.x
	
	fundo_branco.size = retangulo_container.size
	
	var altura_visualizacao: float = 50.0 #define altura base

	for dados_peca in dados.pecas:
		var wrapper_control = Control.new()
		var peca_visual = Sprite2D.new()
		
		peca_visual.texture = load(dados_peca.caminho_textura)
		wrapper_control.custom_minimum_size = Vector2(dados_peca.largura_peca , altura_visualizacao)
		peca_visual.position = Vector2(dados_peca.largura_peca  / 2.0, altura_visualizacao / 2.0)	
		wrapper_control.add_child(peca_visual)
		visualizador_container.add_child(wrapper_control)
		
	#Adiciona o nó de exibição ao contêiner principal
	var separador_altura = Control.new()
	separador_altura.custom_minimum_size = Vector2(0, 60)
	vbox_padroes_salvos.add_child(no_padrao_corte)
	vbox_padroes_salvos.add_child(separador_altura)


func _configurar_botoes_ui():
	# Limpa botões antigos
	for child in vbox_pecas_disponiveis.get_children():
		child.queue_free()
	
	# Botão de Controle de Feedback
	var botao_feedback: Button = cena_botao_ui.instantiate()
	botao_feedback.text = "Mostrar/Esconder Resultado"
	botao_feedback.pressed.connect(func(): _habilitar_desabilitar_botao())
	vbox_pecas_disponiveis.add_child(botao_feedback)
	
	# Botão de Salvar o Padrão de Corte
	var botao_salvar_padrao: Button = cena_botao_ui.instantiate()
	botao_salvar_padrao.text = "Criar Padrão de Corte"
	botao_salvar_padrao.pressed.connect(_on_padraocorte_salvo_pressed)
	vbox_pecas_disponiveis.add_child(botao_salvar_padrao)
	
	# Separador visual
	var separador = Control.new()
	separador.custom_minimum_size = Vector2(0, 10)
	vbox_pecas_disponiveis.add_child(separador)
	
	# Botões de Criação de Peças
	for i in range(pecas_disponiveis.size()):
		var dados_peca = pecas_disponiveis[i]
		
		var instancia_botao: Button = cena_botao_ui.instantiate()
		instancia_botao.text = "%s (%dcm)" % [dados_peca.nome, dados_peca.largura]
		
		instancia_botao.pressed.connect(func(): _on_peca_disponivel_clicada(i))
		vbox_pecas_disponiveis.add_child(instancia_botao)

func _habilitar_desabilitar_botao():
	rotulo_feedback.visible = botao_visivel
	botao_visivel = not botao_visivel

func _on_peca_disponivel_clicada(indice: int):
	var dados_peca = pecas_disponiveis[indice]
	
	#Instancia a cena
	var instancia_peca: PieceScript = cena_peca.instantiate()
	
	#Chama o construtor _init()
	instancia_peca._init(
		dados_peca.largura,
		dados_peca.comprimento,
		dados_peca.caminho_textura
	)
	
	#Conecta o sinal de remoção
	instancia_peca.peca_removida.connect(_on_peca_removida_por_clique)
	pai_pecas.add_child(instancia_peca)
	
	#Define a posição inicial no estoque
	_organizar_pecas_estoque()
	_atualizar_texto_resultado("Peça %s criada. Arraste-a!" % dados_peca.nome)


func _on_peca_removida_por_clique(script_peca: PieceScript):
	if is_instance_valid(script_peca):
		if script_peca.esta_no_container: 
			_tentar_encaixar_peca(script_peca)
		_organizar_pecas_estoque()
		_atualizar_texto_resultado("Peça descartada ou removida do container.")


func _tentar_encaixar_peca(peca: PieceScript) -> bool:
	var largura_restante = largura_container - largura_total_atual
	
	# PEÇA CLICADA PARA SAIR (Retorno ao Estoque)
	if peca.esta_no_container: 
		pecas_encaixadas.remove_at(pecas_encaixadas.find(peca))
		largura_total_atual -= peca.largura_peca 
		peca.esta_no_container = false 
		_reposicionar_pecas_encaixadas()
		_organizar_pecas_estoque()
		_atualizar_texto_resultado("Peça removida do container.")
		return true

	#PEÇA SENDO INSERIDA NO CONTAINER
	if peca.largura_peca <= largura_restante: 
		peca.esta_no_container = true 
		pecas_encaixadas.append(peca)
		largura_total_atual += peca.largura_peca 
		
		_reposicionar_pecas_encaixadas()
		_atualizar_texto_resultado("Peça encaixada com sucesso!")
		return true
	else:
		_atualizar_texto_resultado("Peça não encaixa! Largura restante: %d" % largura_restante)
		peca.position = peca.posicao_original 
		return false

func _reposicionar_pecas_encaixadas():
	var x_atual = 0.0
	for p in pecas_encaixadas:	
		p.position = retangulo_container.position + Vector2(x_atual, 0)
		x_atual += p.largura_peca 

func _organizar_pecas_estoque():
	var y_estoque = retangulo_container.global_position.y + retangulo_container.size.y + 230
	var x_deslocamento = 0.0
	
	for child in pai_pecas.get_children():
		if child is PieceScript and not child.esta_no_container: 
			child.position = Vector2(retangulo_container.global_position.x + x_deslocamento, y_estoque)
			child.posicao_original = child.position 
			x_deslocamento += child.largura_peca + 10 

func _reiniciar_jogo():
	largura_total_atual = 0.0
	pecas_encaixadas.clear()
	
	for child in pai_pecas.get_children():
		child.queue_free()
	
	_organizar_pecas_estoque()
	_atualizar_texto_resultado("Arraste as peças para o Container!")

func _atualizar_texto_resultado(mensagem_status: String = ""):
	if is_instance_valid(retangulo_container):
		largura_container = retangulo_container.size.x
	
	var eficiencia = (largura_total_atual / largura_container) * 100.0 if largura_container > 0 else 0.0
	var nao_encaixadas = pai_pecas.get_child_count() - pecas_encaixadas.size()

	var texto_resultado = "--- Resultado do Corte ---\n"
	texto_resultado += "Largura Total do Container: %d\n" % largura_container
	texto_resultado += "Largura Ocupada: %d\n" % largura_total_atual
	texto_resultado += "Eficiência: %.2f%%\n" % eficiencia
	texto_resultado += "Peças Encaixadas: %d | Estoque/Descartadas: %d\n" % [pecas_encaixadas.size(), nao_encaixadas]
	
	if mensagem_status:
		texto_resultado += "\nSTATUS: %s" % mensagem_status

	rotulo_feedback.text = texto_resultado
	rotulo_feedback.position = Vector2(retangulo_container.position.x, retangulo_container.position.y + retangulo_container.size.y + 5)
