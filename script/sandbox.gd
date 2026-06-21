extends Control

# Cenas auxiliares reutilizáveis
var cena_padrao_visual = load("res://scene/aux_scene/Padrao_Corte.tscn")
var miniatura = load("res://scene/aux_scene/miniatura_modelo_chapa.tscn")

# Sub-cenas criadas para o Sandbox
var item_demanda_sandbox = load("res://scene/aux_scene/item_demanda_sandbox.tscn")
var item_padrao_inventario = load("res://scene/aux_scene/item_padrao_inventario.tscn")
var bloco_peca_chapa = load("res://scene/aux_scene/bloco_peca_chapa.tscn")

# Caminhos do Solver Python
var PYTHON_PATH = ProjectSettings.globalize_path("res://PythonFiles/venv/Scripts/python.exe")
var PYTHON_SCRIPT = ProjectSettings.globalize_path("res://PythonFiles/resolve_modelagem_pu.py")
var OUTPUT_FILE_PATH = ProjectSettings.globalize_path("res://resolve_modelagem.json")

# Onreadys da árvore estruturada
@onready var container_armas_botoes = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/VBox/ContainerArmasBotoes
@onready var visualizador_chapa_atual = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/VBox/VisualizadorChapaAtual
@onready var info_desperdicio = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/VBox/LinhaAcoesCriador/InfoDesperdicio
@onready var btn_adicionar_ao_inventario = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/VBox/LinhaAcoesCriador/BtnAdicionarAoInventario
@onready var btn_limpar_chapa = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/VBox/LinhaAcoesCriador/BtnLimparChapa

@onready var grid_demandas_armas = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/PainelDemandas/VBox/GridDemandasArmas
@onready var container_modelagem_padroes = $MainMargin/LayoutPrincipal/PainelDireito/ScrollInventario/ContainerModelagemPadroes

@onready var resultado_txt_label = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/PainelAcoesFinais/ResultadoTxtLabel
@onready var btn_resolver_sandbox = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/PainelAcoesFinais/BtnResolverSandbox
@onready var btn_voltar = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelCriador/PainelAcoesFinais/BtnVoltar

# Variáveis de controle do Sandbox (Isoladas do ciclo principal do jogo)
var largura_maxima_chapa: float = 0.0
var comprimento_acumulado_atual: float = 0.0
var chapa_em_construcao_composicao: Array = []
var inventario_padroes_completos: Array = [] 

func _ready() -> void:
	largura_maxima_chapa = 500.0
	inventario_padroes_completos = []
	
	btn_limpar_chapa.pressed.connect(_limpar_chapa_atual)
	btn_adicionar_ao_inventario.pressed.connect(_salvar_padrao_no_inventario)
	btn_resolver_sandbox.pressed.connect(_on_resolver_sandbox_pressed)
	btn_voltar.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Cena_1.tscn"))
	
	_inicializar_interface_sandbox()

func _inicializar_interface_sandbox() -> void:
	for child in container_armas_botoes.get_children():
		child.queue_free()
		
	for i in range(Global.pecas_disponiveis.size()):
		var peca = Global.pecas_disponiveis[i]
		var btn_arma = Button.new()
		btn_arma.text = " + " + peca.nome
		btn_arma.pressed.connect(func(): _adicionar_peca_a_chapa(i))
		container_armas_botoes.add_child(btn_arma)
		
	for child in grid_demandas_armas.get_children():
		child.queue_free()
		
	chapa_em_construcao_composicao.resize(Global.pecas_disponiveis.size())
	chapa_em_construcao_composicao.fill(0)
	
	for i in range(Global.pecas_disponiveis.size()):
		var item_dem = item_demanda_sandbox.instantiate()
		item_dem.name = "DemandaItem_" + str(i)
		
		var peca = Global.pecas_disponiveis[i]
		item_dem.find_child("TexturaArma").texture = load(peca.caminho_textura)
		item_dem.find_child("LabelNome").text = peca.nome
		
		var input_edit = item_dem.find_child("InputDemanda") as LineEdit
		input_edit.text = "0"
		input_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
		input_edit.text_changed.connect(func(novo_texto):
			input_edit.text = RegEx.create_from_string("[0-9]*").search(novo_texto).get_string()
			input_edit.caret_column = input_edit.text.length()
		)
		
		grid_demandas_armas.add_child(item_dem)
		
	_limpar_chapa_atual()
	_atualizar_lista_inventario_visual()

func _adicionar_peca_a_chapa(id_peca: int) -> void:
	var peca = Global.pecas_disponiveis[id_peca]
	
	if comprimento_acumulado_atual + peca.largura > largura_maxima_chapa:
		info_desperdicio.text = "Não cabe mais nesta chapa!"
		return
		
	comprimento_acumulado_atual += peca.largura
	chapa_em_construcao_composicao[id_peca] += 1
	
	var bloco = bloco_peca_chapa.instantiate()
	bloco.custom_minimum_size = Vector2(peca.largura * 0.1, 50) 
	bloco.find_child("Textura").texture = load(peca.caminho_textura)
	visualizador_chapa_atual.add_child(bloco)
	
	_atualizar_calculo_desperdicio()

func _atualizar_calculo_desperdicio() -> void:
	if comprimento_acumulado_atual == 0:
		info_desperdicio.text = "Desperdício: 100%"
		return
	var sobra = largura_maxima_chapa - comprimento_acumulado_atual
	var pct_perda = (sobra / largura_maxima_chapa) * 100.0
	info_desperdicio.text = "Desperdício: %.1f%% (%d / %d mm)" % [pct_perda, sobra, largura_maxima_chapa]

func _limpar_chapa_atual() -> void:
	for child in visualizador_chapa_atual.get_children():
		child.queue_free()
	comprimento_acumulado_atual = 0.0
	chapa_em_construcao_composicao.fill(0)
	_atualizar_calculo_desperdicio()

func _salvar_padrao_no_inventario() -> void:
	if comprimento_acumulado_atual == 0: return
	if inventario_padroes_completos.size() >= 5:
		resultado_txt_label.text = "Limite máximo de 5 padrões atingido!"
		resultado_txt_label.modulate = Color.RED
		return
		
	var sobra = largura_maxima_chapa - comprimento_acumulado_atual
	var pct_perda = (sobra / largura_maxima_chapa) * 100.0
	
	var novo_padrao = {
		"composicao": chapa_em_construcao_composicao.duplicate(),
		"desperdicio": pct_perda
	}
	
	inventario_padroes_completos.append(novo_padrao)
	_limpar_chapa_atual()
	_atualizar_lista_inventario_visual()

func _atualizar_lista_inventario_visual() -> void:
	for child in container_modelagem_padroes.get_children():
		child.queue_free()
		
	for i in range(inventario_padroes_completos.size()):
		var dados = inventario_padroes_completos[i]
		var item_inv = item_padrao_inventario.instantiate()
		
		item_inv.find_child("LabelIndice").text = "x" + str(i + 1)
		item_inv.find_child("LabelIndice").add_theme_font_size_override("font_size", 26)
		item_inv.find_child("LabelDesperdicio").text = "Perda: %.1f%%" % dados["desperdicio"]
		
		var visualizador = item_inv.find_child("InstanciaPadraoVisual").find_child("Visualizador_Padrao")
		if visualizador:
			_desenhar_sprites_no_visualizador_sandbox(visualizador, dados["composicao"])
			
		var btn_rem = item_inv.find_child("BtnRemover") as Button
		btn_rem.pressed.connect(func(): _remover_padrao_do_inventario(i))
		
		container_modelagem_padroes.add_child(item_inv)

func _desenhar_sprites_no_visualizador_sandbox(container: HBoxContainer, composicao: Array) -> void:
	for child in container.get_children():
		child.queue_free()
	for i in range(composicao.size()):
		var qtd = composicao[i]
		var peca = Global.pecas_disponiveis[i]
		for n in range(qtd):
			var wrapper = Control.new(); wrapper.custom_minimum_size = Vector2(peca.largura * 0.05, 40)
			var s = Sprite2D.new(); s.texture = load(peca.caminho_textura)
			if s.texture:
				var t_size = s.texture.get_size()
				s.scale = Vector2((peca.largura * 0.05) / t_size.x, 40.0 / t_size.y)
				s.position = Vector2((peca.largura * 0.05) / 2.0, 20)
			wrapper.add_child(s)
			container.add_child(wrapper)

func _remover_padrao_do_inventario(indice: int) -> void:
	inventario_padroes_completos.remove_at(indice)
	_atualizar_lista_inventario_visual()

func _on_resolver_sandbox_pressed() -> void:
	if inventario_padroes_completos.is_empty():
		resultado_txt_label.text = "Adicione ao menos um padrão de corte à direita!"
		resultado_txt_label.modulate = Color.RED
		return
		
	var matriz_demanda_sandbox = []
	matriz_demanda_sandbox.resize(Global.pecas_disponiveis.size())
	matriz_demanda_sandbox.fill(0)
	
	for i in range(Global.pecas_disponiveis.size()):
		var item_dem = grid_demandas_armas.find_child("DemandaItem_" + str(i), true, false)
		if item_dem:
			var input = item_dem.find_child("InputDemanda") as LineEdit
			matriz_demanda_sandbox[i] = int(input.text.strip_edges()) if input.text.strip_edges() != "" else 0
			
	var composicoes_enviadas = []
	for padrao in inventario_padroes_completos:
		composicoes_enviadas.append(padrao["composicao"])
		
	var args = [PYTHON_SCRIPT, JSON.stringify(matriz_demanda_sandbox), JSON.stringify(composicoes_enviadas), OUTPUT_FILE_PATH]
	OS.execute(PYTHON_PATH, args)
	
	if FileAccess.file_exists(OUTPUT_FILE_PATH):
		var file = FileAccess.open(OUTPUT_FILE_PATH, FileAccess.READ)
		var resultado = JSON.parse_string(file.get_as_text())
		file.close()
		
		if resultado and resultado.get("status") == "Optimal":
			var solucao_lista = resultado.get("solucao", [])
			var texto_resultado = "Resultado Otimizado Sandbox:\n"
			var total_chapas = 0
			
			for j in range(solucao_lista.size()):
				var qtd_cortes = int(solucao_lista[j])
				total_chapas += qtd_cortes
				texto_resultado += "Padrão x%d: cortar %d vez(es)\n" % [(j + 1), qtd_cortes]
				
			texto_resultado += "\nTotal de Chapas Utilizadas: %d" % total_chapas
			resultado_txt_label.text = texto_resultado
			resultado_txt_label.modulate = Color.GREEN
		else:
			resultado_txt_label.text = "Inviável: Os padrões atuais não atendem a demanda!"
			resultado_txt_label.modulate = Color.YELLOW
