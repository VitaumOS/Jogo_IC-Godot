extends Control

var cena_padrao_visual = load("res://scene/aux_scene/Padrao_Corte.tscn")
var restricao = load("res://scene/aux_scene/restricao.tscn")
var miniatura = load("res://scene/aux_scene/miniatura_modelo_chapa.tscn")
var termo_restricao = load("res://scene/aux_scene/termo_restricao.tscn")

@onready var funcao_objetivo_lbl = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelFuncao/FuncaoObjetivo
@onready var container_funcao = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelFuncao
@onready var container_restricoes = $MainMargin/LayoutPrincipal/PainelEsquerdo/ContainerRestricoes
@onready var container_padroes_selecao = $MainMargin/LayoutPrincipal/PainelDireito/ScrollPadroes/ContainerPadroesSelecao
@onready var resultado_lbl = $ResultadoCortesLabel
@onready var btn_resolver = $MainMargin/LayoutPrincipal/PainelEsquerdo/Resolver
@onready var btn_voltar = $MainMargin/LayoutPrincipal/PainelEsquerdo/Voltar

var PYTHON_PATH = ProjectSettings.globalize_path("res://PythonFiles/venv/Scripts/python.exe")
var PYTHON_SCRIPT = ProjectSettings.globalize_path("res://PythonFiles/resolve_modelagem_pu.py")
var OUTPUT_FILE_PATH = ProjectSettings.globalize_path("res://resolve_modelagem.json")

var lista_padroes_disponiveis: Array = []       
var padroes_selecionados_indices: Array = []    
var inputs_demanda: Dictionary = {}              

func _ready() -> void:
	
	# Carrega os padrões salvos do inventário do jogador
	if Global.padroes_desbloqueados != null:
		lista_padroes_disponiveis = Global.padroes_desbloqueados
	else:
		lista_padroes_disponiveis = []
		
	_gerar_lista_direita_padroes()
	_gerar_restricoes_demanda()
	_atualizar_equacoes_na_tela()
	Global._verificar_gatilho_tutorial("primeira_modelagem")


func _gerar_lista_direita_padroes() -> void:
	for child in container_padroes_selecao.get_children():
		child.queue_free()
	
	var i =0
	for padrao in Global.padroes_desbloqueados:
		var h_box_item = HBoxContainer.new()
		h_box_item.custom_minimum_size = Vector2(0, 60)
		
		var btn_toggle = Button.new()
		btn_toggle.toggle_mode = true
		btn_toggle.text = " Incluir "
		btn_toggle.custom_minimum_size = Vector2(90, 0)
		h_box_item.add_child(btn_toggle)
		
		var instancia_visual = cena_padrao_visual.instantiate()
		h_box_item.add_child(instancia_visual)
			
		var visualizador = instancia_visual.find_child("Visualizador_Padrao")
		_desenhar_sprites_no_visualizador(visualizador, padrao.get("composicao", []))
		
		btn_toggle.toggled.connect(func(is_pressed):
			_alternar_padrao_na_modelagem(i, is_pressed, btn_toggle)
		)
		container_padroes_selecao.add_child(h_box_item)
		i=i+1

func _desenhar_sprites_no_visualizador(container: HBoxContainer, composicao: Array) -> void:
	for i in range(composicao.size()):
		var qtd = composicao[i]
		var peca = Global.pecas_disponiveis[i]
		for n in range(qtd):
			var wrapper = Control.new(); wrapper.custom_minimum_size = Vector2(peca.largura, 50)
			var s = Sprite2D.new(); s.texture = load(peca.caminho_textura)
			if s.texture:
				var t_size = s.texture.get_size()
				s.scale = Vector2(peca.largura / t_size.x, 50.0 / t_size.y)
				s.position = Vector2(peca.largura / 2.0, 25)
			wrapper.add_child(s)
			container.add_child(wrapper)

func _alternar_padrao_na_modelagem(idx_padrao: int, is_active: bool, botao: Button) -> void:
	if is_active:
		if not padroes_selecionados_indices.has(idx_padrao):
			padroes_selecionados_indices.append(idx_padrao)
	else:
		padroes_selecionados_indices.erase(idx_padrao)
	_gerar_restricoes_demanda()
	_atualizar_equacoes_na_tela()
	_reorganizar_texto_botoes()

func _reorganizar_texto_botoes() -> void:
	var idx_atual = 0
	for item in container_padroes_selecao.get_children():
		var btn = item.get_child(0) as Button
		if btn.is_pressed():
			var posicao_na_equacao = padroes_selecionados_indices.find(idx_atual)
			btn.text = " Ativo [%d] " % (posicao_na_equacao + 1)
		else:
			btn.text = " Incluir "
	idx_atual += 1

func _gerar_restricoes_demanda() -> void:
	if not container_restricoes: return
	
	for child in container_restricoes.get_children():
		child.queue_free()
		
	if not Global.contrato_ativo: return
	
	var demanda_contrato = Global.contrato_ativo.demanda
	for i in range(demanda_contrato.size()):
		if demanda_contrato[i] > 0:
			var rest = restricao.instantiate()
			rest.find_child("Peca").texture = load(Global.pecas_disponiveis[i].caminho_textura)
			var lbl_tecnica = rest.find_child("Restricao")
			lbl_tecnica.name = "CoeficientesPeca_" + str(i)

			for child in lbl_tecnica.get_children():
				child.queue_free()
				
			var primeiro_termo = true
			for j in range(padroes_selecionados_indices.size()):
				var padrao = Global.padroes_desbloqueados[padroes_selecionados_indices[j]]
				var comp_padrao = padrao.get("composicao", [])
				var qtd_na_chapa = comp_padrao[i] if i < comp_padrao.size() else 0
				
				if qtd_na_chapa > 0:
					if not primeiro_termo:
						var lbl_mais = Label.new()
						lbl_mais.text = "     +"
						lbl_mais.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						lbl_mais.add_theme_font_size_override("font_size", 26)
						lbl_tecnica.add_child(lbl_mais)
					primeiro_termo = false
					
					var termo = termo_restricao.instantiate()
					termo.find_child("Qtd").text = str(qtd_na_chapa)        
					termo.find_child("Miniatura").find_child("Numero").text = str(j + 1)
					lbl_tecnica.add_child(termo)
			if primeiro_termo:
				var lbl_zero = Label.new()
				lbl_zero.text = "0"
				lbl_zero.add_theme_font_size_override("font_size", 26)
				lbl_tecnica.add_child(lbl_zero)
			
			rest.find_child("demanda").text = str(demanda_contrato[i])
			container_restricoes.add_child(rest)

func _atualizar_equacoes_na_tela() -> void:
	var termos_funcao_obj = []
	for i in range(padroes_selecionados_indices.size()):
		termos_funcao_obj.append(str(i + 1))
		
	if termos_funcao_obj.is_empty():
		funcao_objetivo_lbl.text = "Minimizar Z = 0"
		for child in container_funcao.get_children():
			if child != funcao_objetivo_lbl:
				child.queue_free()
	else:
		funcao_objetivo_lbl.text = "Minimizar Z = "
		for child in container_funcao.get_children():
			if child != funcao_objetivo_lbl:
				child.queue_free()

		for i in range(padroes_selecionados_indices.size()):
			if i > 0:
				var lbl_mais = Label.new(); lbl_mais.text = "    +"
				lbl_mais.add_theme_font_size_override("font_size", 26)
				container_funcao.add_child(lbl_mais)
			var mini = miniatura.instantiate()
			container_funcao.add_child(mini)
			var num_node = mini.find_child("Numero")
			num_node.text = str(i + 1)

func _on_btn_resolver_pressed() -> void:
	if padroes_selecionados_indices.is_empty(): return
		
	var composicoes_enviadas = []
	for idx in padroes_selecionados_indices:
		var padrao = Global.padroes_desbloqueados[idx]
		composicoes_enviadas.append(padrao.get("composicao", []))
		
	var matriz_demanda_manual = []
	matriz_demanda_manual.resize(Global.pecas_disponiveis.size())
	matriz_demanda_manual.fill(0)
	
	if Global.contrato_ativo:
		for i in range(Global.contrato_ativo.demanda.size()):
			matriz_demanda_manual[i] = Global.contrato_ativo.demanda[i]

	var args = [PYTHON_SCRIPT, JSON.stringify(matriz_demanda_manual), JSON.stringify(composicoes_enviadas), OUTPUT_FILE_PATH]
	OS.execute(PYTHON_PATH, args)
	
	if FileAccess.file_exists(OUTPUT_FILE_PATH):
		var file = FileAccess.open(OUTPUT_FILE_PATH, FileAccess.READ)
		var resultado = JSON.parse_string(file.get_as_text())
		file.close()
		
		if resultado and resultado.get("status") == "Optimal":
			var solucao_lista = resultado.get("solucao", [])
			var texto_resultado = "Plano de Corte Recomendado:\n"
			var total_chapas = 0
			
			for j in range(solucao_lista.size()):
				var qtd_cortes = int(solucao_lista[j])
				total_chapas += qtd_cortes
				texto_resultado += "Padrão x%d: cortar %d vez(es)\n" % [(j + 1), qtd_cortes]
			
			texto_resultado += "\nTotal de Chapas Utilizadas: %d" % total_chapas
			if resultado_lbl:
				resultado_lbl.text = texto_resultado
				resultado_lbl.modulate = Color.GREEN
			

func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
