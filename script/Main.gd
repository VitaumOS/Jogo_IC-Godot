# Main.gd
extends Node2D


# Cenas Exportadas
@export var cena_peca: PackedScene
@export var cena_botao_ui: PackedScene
@export var cena_padrao_corte: PackedScene

# Referências de Nós (@onready)
@onready var retangulo_container: ColorRect = $Container
@onready var pai_pecas: Node2D = $RectanglesParent
@onready var rotulo_feedback: Label = $UI/FeedbackLabel
@onready var vbox_pecas_disponiveis: VBoxContainer = $UI/AvailablePiecesVBox
@onready var vbox_padroes_salvos: VBoxContainer = $UI/PadraoCorteSalvo
@onready var rotulo_demanda: Label = $UI/DemandaLabel # Rótulo para mostrar a demanda

# Variáveis
var largura_container: float
var largura_total_atual: float = 0.0
var pecas_encaixadas: Array[PieceScript] = [] # Mantido, mas não usado na nova lógica
var botao_visivel: bool
var padroes_corte_salvos: Array = [] # Dicionários de dados para exibição
var padroes_corte_salvos_valor: Array = [] # Array de Arrays numéricos [[4,0,0], [0,3,0], [0,0,2]]
var padroes_selecionados: Array = [] # Índices dos padrões ativos (0, 1, 2, ...)

var PYTHON_PATH = ProjectSettings.globalize_path("res://PythonFiles/venv/Scripts/python.exe")
var PYTHON_SCRIPT = ProjectSettings.globalize_path("res://PythonFiles/resolve_pcu_pl.py")
const OUTPUT_FILE_NAME = "res://pulp_solution.json" # Mudando para user:// para garantir escrita

var demanda: Array = [5, 3, 2] # Adaga(P), Espada L(M), Espada G(L)

# Dados das Peças
var pecas_disponiveis: Array = [
	{"nome": "Adaga (P)", "largura": 110.0, "comprimento": 50.0, "caminho_textura": "res://Sprite/adaga.png"},
	{"nome": "Espada L (M)", "largura": 150.0, "comprimento": 50.0, "caminho_textura": "res://Sprite/Esp_Larg.png"},
	{"nome": "Espada G (L)", "largura": 180.0, "comprimento": 50.0, "caminho_textura": "res://Sprite/Esp_Grande.png"},
]

func _criar_padroes_automaticos():
	# Padrões automáticos que você solicitou: [4,0,0], [0,3,0], [0,0,2]
	var padroes_iniciais = [
		[4, 0, 0], # Padrão 1
		[0, 3, 0], # Padrão 2
		[0, 0, 2], # Padrão 3
		[1, 0, 2], # Padrão 4
		[1, 1, 1]  # Padrão 5
	]
	var larguras_padrao = []
	
	for padrao in padroes_iniciais:
		var soma_larguras = 0
		for i in range(pecas_disponiveis.size()):
			soma_larguras += pecas_disponiveis[i].largura * padrao[i]
		larguras_padrao.append(soma_larguras)

	for i in range(padroes_iniciais.size()):
		var padrao_numerico = padroes_iniciais[i]
		var largura_ocupada = larguras_padrao[i]
		
		var dados_padrao = {
			"largura": largura_ocupada,
			"eficiencia": (largura_ocupada / largura_container) * 100.0,
			"pecas": [], # Lista de peças para exibição visual (apenas ilustrativo)
			"nome": "Padrão %d" % (i + 1)
		}
		
		# Populando a lista 'pecas' para a exibição visual
		for j in range(padrao_numerico.size()):
			var tipo_peca = pecas_disponiveis[j]
			for _k in range(padrao_numerico[j]):
				dados_padrao.pecas.append({
					"largura_peca": tipo_peca.largura,
					"caminho_textura": tipo_peca.caminho_textura
				})
		
		padroes_corte_salvos_valor.append(padrao_numerico)
		padroes_corte_salvos.append(dados_padrao)
		_exibir_padrao_salvo(dados_padrao)
		
		# Inicialmente, todos os padrões estão selecionados
		padroes_selecionados.append(i) 

func _on_gerar_demanda_aleatoria_pressed():
	var nova_demanda: Array = []
	for _i in range(pecas_disponiveis.size()):
		# Gera demanda aleatória entre 1 e 10 para cada tipo de peça
		nova_demanda.append(randi_range(0, 70)) 
		
	demanda = nova_demanda
	
	_atualizar_texto_resultado("Nova Demanda Aleatória Gerada: %s" % demanda)
	_atualizar_rotulo_demanda()

	

func _atualizar_rotulo_demanda():
	var texto_demanda = "Demanda Atual:\n"
	for i in range(demanda.size()):
		var nome_peca = pecas_disponiveis[i].nome
		texto_demanda += " - %s: %d\n" % [nome_peca, demanda[i]]
	rotulo_demanda.text = texto_demanda

# --- MODIFICAÇÕES NAS FUNÇÕES EXISTENTES ---

func _ready():
	add_to_group("main_logic")
	
	botao_visivel = false
	retangulo_container.size.x = 498
	retangulo_container.size.y = 50
	largura_container = retangulo_container.size.x
	retangulo_container.color = Color.WHITE
	retangulo_container.position = Vector2(300, 100)
	

	
	# CRIAÇÃO AUTOMÁTICA DOS PADRÕES
	_criar_padroes_automaticos() 
	
	_configurar_botoes_ui()
	_reiniciar_jogo() # Limpa as peças, mas não a UI
	_atualizar_rotulo_demanda()

# ESTA FUNÇÃO É REMOVIDA
# func cria_padraocorte(padrao): pass 

func _configurar_botoes_ui():
	# Limpa botões antigos
	for child in vbox_pecas_disponiveis.get_children():
		child.queue_free()
	
	# 1. Botão de Gerar Demanda Aleatória
	var botao_demanda: Button = cena_botao_ui.instantiate()
	botao_demanda.text = "Gerar Demanda Aleatória"
	botao_demanda.pressed.connect(_on_gerar_demanda_aleatoria_pressed)
	vbox_pecas_disponiveis.add_child(botao_demanda)
	
	#Selecionar a quantidade de vezes que vai cortar tal padrão
	for i in range(padroes_corte_salvos.size()):
		var barra_selecao = TextEdit.new()
		barra_selecao.size.y = 200
		vbox_pecas_disponiveis.add_child(barra_selecao)
	
	#Botão de Resolução do PCU
	var botao_resolver_pcu: Button = cena_botao_ui.instantiate()
	botao_resolver_pcu.text = "Resolver PCU (Calcular o Mínimo)"
	botao_resolver_pcu.pressed.connect(_resolver_pcu)
	vbox_pecas_disponiveis.add_child(botao_resolver_pcu)
	
	#Separador visual
	var separador = Control.new()
	separador.custom_minimum_size = Vector2(0, 10)
	vbox_pecas_disponiveis.add_child(separador)
	
func _resolver_pcu():

	var padroes_para_resolver: Array = []
	for index in padroes_selecionados:
		padroes_para_resolver.append(padroes_corte_salvos_valor[index])
	var args = []
	
	args.append(PYTHON_SCRIPT)
	args.append(demanda)
	for padrao in padroes_para_resolver:
		args.append(padrao)

	var exit_code = OS.execute(PYTHON_PATH, args)
	
	var z_otimo_pulp: int = -1

	if exit_code == 0:
		var file_path = ProjectSettings.globalize_path(OUTPUT_FILE_NAME)
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json_data: Dictionary = JSON.parse_string(json_string)

		#Verifica e processa o resultado
		if json_data.get("status") == "Optimal":
			var chapas_usadas: int = json_data["chapas_usadas"]
			var plano_corte: Dictionary = json_data["plano_corte"]
			
			z_otimo_pulp = chapas_usadas
			
			#Montagem da Mensagem de Exibição
			var texto_resultado = "Chapas Mínimas (Z): %d\n" % chapas_usadas
			texto_resultado += "Plano de Corte:\n"

			var nomes_padroes_usados = []
			for nome in plano_corte.keys():
				var index = int(nome.split("_")[1]) - 1
				nomes_padroes_usados.append("Padrão %d" % (index + 1))
			
			nomes_padroes_usados.sort()
			
			for i in range(nomes_padroes_usados.size()):
				var nome_padrao_display = nomes_padroes_usados[i]
				var indice_original = -1
				for p_idx in range(padroes_corte_salvos.size()):
					if padroes_corte_salvos[p_idx].nome == nome_padrao_display:
						indice_original = p_idx
						break
				
				if indice_original != -1:
					var chave_pulp = "Padrão_%d" % (indice_original + 1)
					var uso = plano_corte.get(chave_pulp, 0) # Obtém o uso correto
					if uso > 0:
						texto_resultado += " - %s: %d vezes\n" % [nome_padrao_display, uso]
			
			var chapas_cortadas_pelo_jogador = 2 
			var proximidade = 0.0
			
			if chapas_cortadas_pelo_jogador >= z_otimo_pulp:
				proximidade = (float(z_otimo_pulp) / float(chapas_cortadas_pelo_jogador)) * 100.0
			
			texto_resultado += "\nAnálise de Eficiência \n"
			texto_resultado += "Chapas Cortadas: %d\n" % chapas_cortadas_pelo_jogador
			texto_resultado += "Proximidade do Ótimo (Z): %.2f%%\n" % proximidade
			
			_atualizar_texto_resultado(texto_resultado)



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
	
	var altura_visualizacao: float = 50.0 #Define altura base

	for dados_peca in dados.pecas:
		var wrapper_control = Control.new()
		var peca_visual = Sprite2D.new()
		
		peca_visual.texture = load(dados_peca.caminho_textura)
		wrapper_control.custom_minimum_size = Vector2(dados_peca.largura_peca , altura_visualizacao)
		peca_visual.position = Vector2(dados_peca.largura_peca/ 2.0, altura_visualizacao / 2.0)
		wrapper_control.add_child(peca_visual)
		visualizador_container.add_child(wrapper_control)
		
	#Adiciona o nó de exibição ao contêiner principal
	var separador_altura = Control.new()
	separador_altura.custom_minimum_size = Vector2(0, 60)
	vbox_padroes_salvos.add_child(no_padrao_corte)
	vbox_padroes_salvos.add_child(separador_altura)

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


	var texto_resultado = "Resultado do Corte\n"
	
	if mensagem_status:
		texto_resultado += "\nSTATUS: %s" % mensagem_status

	rotulo_feedback.text = texto_resultado
	rotulo_feedback.position = Vector2(400, 40)
