extends Control

# --- CAMINHO FIXO DA CENA DO PADRÃO ---
var cena_padrao_visual = load("res://scene/Padrao_Corte.tscn")

# --- REFERÊNCIAS DOS NÓS (USANDO UNIQUE NAMES %) ---
@onready var funcao_objetivo_lbl = $MainMargin/LayoutPrincipal/PainelEsquerdo/FuncaoObjetivo
@onready var container_restricoes = $MainMargin/LayoutPrincipal/PainelEsquerdo/ScrollRestricoes/ContainerRestricoes
@onready var container_padroes_selecao = $MainMargin/LayoutPrincipal/PainelDireito/ScrollPadroes/ContainerPadroesSelecao
@onready var resultado_lbl = $ResultadoCortesLabel
@onready var btn_resolver = $MainMargin/LayoutPrincipal/PainelEsquerdo/Resolver
@onready var btn_voltar = $MainMargin/LayoutPrincipal/PainelEsquerdo/Voltar

# --- CAMINHOS DO SOLVER ---
var PYTHON_PATH = ProjectSettings.globalize_path("res://PythonFiles/venv/Scripts/python.exe")
var PYTHON_SCRIPT = ProjectSettings.globalize_path("res://PythonFiles/resolve_modelagem_pu.py")
var OUTPUT_FILE_PATH = ProjectSettings.globalize_path("res://resolve_modelagem.json")

# --- CONTROLE INTERNO ---
var lista_padroes_disponiveis: Array = []       
var padroes_selecionados_indices: Array = []    
var inputs_demanda: Dictionary = {}             

func _ready() -> void:
	
	# Carrega os padrões salvos do inventário do jogador
	if Global.get("padroes_salvos") != null:
		lista_padroes_disponiveis = Global.padroes_salvos
	else:
		lista_padroes_disponiveis = []
		
	# Inicializa a interface simplificada
	_gerar_lista_direita_padroes()
	_gerar_restricoes_demanda()
	_atualizar_equacoes_na_tela()

# --- PAINEL DIREITO: SEUS PADRÕES DISPONÍVEIS ---
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
		
	_atualizar_equacoes_na_tela()
	_reorganizar_texto_botoes()

func _reorganizar_texto_botoes() -> void:
	var idx_atual = 0
	for item in container_padroes_selecao.get_children():
		if item is HBoxContainer:
			var btn = item.get_child(0) as Button
			if btn:
				if btn.is_pressed():
					var posicao_na_equacao = padroes_selecionados_indices.find(idx_atual)
					btn.text = " Ativo [x%d] " % (posicao_na_equacao + 1)
				else:
					btn.text = " Incluir "
		idx_atual += 1

# --- PAINEL ESQUERDO: FORMULAÇÃO MATEMÁTICA ---
func _gerar_restricoes_demanda() -> void:
	if not container_restricoes: return
	
	for child in container_restricoes.get_children():
		child.queue_free()
	inputs_demanda.clear()
	
	if not Global.contrato_ativo: return
		
	var demanda_contrato = Global.contrato_ativo.demanda
	for i in range(demanda_contrato.size()):
		if demanda_contrato[i] > 0:
			var nome_peca = Global.pecas_disponiveis[i].nome
			
			var h_box = HBoxContainer.new()
			h_box.alignment = BoxContainer.ALIGNMENT_CENTER
			
			var lbl_nome = Label.new()
			lbl_nome.text = nome_peca + ": "
			h_box.add_child(lbl_nome)
			
			var lbl_tecnica = Label.new()
			lbl_tecnica.name = "CoeficientesPeca_" + str(i)
			lbl_tecnica.text = "0"
			h_box.add_child(lbl_tecnica)
			
			var lbl_sinal = Label.new()
			lbl_sinal.text = "  >=  "
			h_box.add_child(lbl_sinal)
			
			var input_qtd = LineEdit.new()
			input_qtd.custom_minimum_size = Vector2(60, 0)
			input_qtd.alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			input_qtd.text_changed.connect(func(novo_texto):
				input_qtd.text = RegEx.create_from_string("[0-9]*").search(novo_texto).get_string()
			)
			
			h_box.add_child(input_qtd)
			container_restricoes.add_child(h_box)
			inputs_demanda[i] = input_qtd

func _atualizar_equacoes_na_tela() -> void:
	var termos_funcao_obj = []
	for i in range(padroes_selecionados_indices.size()):
		termos_funcao_obj.append("x" + str(i + 1))
		
	if termos_funcao_obj.is_empty():
		funcao_objetivo_lbl.text = "Função Objetivo:\nMin Z = 0"
	else:
		funcao_objetivo_lbl.text = "Função Objetivo:\nMin Z = " + " + ".join(termos_funcao_obj)
		
	if not Global.contrato_ativo: return
	var demanda_contrato = Global.contrato_ativo.demanda
	
	# Varre cada tipo de peça da demanda do contrato
	for i in range(demanda_contrato.size()):
		if demanda_contrato[i] > 0:
			var lbl_coef = container_restricoes.find_child("CoeficientesPeca_" + str(i), true, false) as Label
			if lbl_coef:
				var termos_da_peca = []
				
				# Em vez de olhar todos os desbloqueados, varre estritamente os incluídos
				for j in range(padroes_selecionados_indices.size()):
					var idx_padrao_original = padroes_selecionados_indices[j]
					var padrao = Global.padroes_desbloqueados[idx_padrao_original]
					
					var comp_padrao = padrao.get("composicao", [])
					var qtd_na_chapa = comp_padrao[i] if i < comp_padrao.size() else 0
					
					# Se o padrão incluído contiver essa peça, j+1 casa com a numeração do x da F.O.
					if qtd_na_chapa > 0:
						termos_da_peca.append(str(qtd_na_chapa) + "x" + str(j + 1))
						
				if termos_da_peca.is_empty():
					lbl_coef.text = "0"
				else:
					lbl_coef.text = " + ".join(termos_da_peca)

# --- BOTÕES DE EXECUÇÃO ---
func _on_btn_resolver_pressed() -> void:
	if padroes_selecionados_indices.is_empty(): return
		
	var composicoes_enviadas = []
	for idx in padroes_selecionados_indices:
		var padrao = Global.padroes_desbloqueados[idx]
		composicoes_enviadas.append(padrao.get("composicao", []))
		
	var matriz_demanda_manual = []
	matriz_demanda_manual.resize(Global.pecas_disponiveis.size())
	matriz_demanda_manual.fill(0)
	
	for idx_peca in inputs_demanda.keys():
		var input_edit = inputs_demanda[idx_peca] as LineEdit
		var valor_digitado = int(input_edit.text.strip_edges())
		var valor_real_contrato = Global.contrato_ativo.demanda[idx_peca]
		
		if input_edit.text.strip_edges() == "" or valor_digitado != valor_real_contrato:
			if resultado_lbl:
				resultado_lbl.text = "Erro: Valores digitados nas restrições divergem do Contrato!"
			return
		matriz_demanda_manual[idx_peca] = valor_digitado

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
