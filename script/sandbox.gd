extends Control

var restricao = load("res://scene/aux_scene/restricao.tscn")
var miniatura = load("res://scene/aux_scene/miniatura_modelo_chapa.tscn")
var termo_restricao = load("res://scene/aux_scene/termo_restricao.tscn")
var cena_loading_preload = load("res://scene/aux_scene/loading.tscn")
var padrao_corte_model = load("res://scene/aux_scene/padrao_corte_modelagem.tscn")
var cena_mostra_cortes = load("res://scene/aux_scene/cena_mostra_cortes.tscn")

@onready var funcao_objetivo_lbl = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelFuncao/FuncaoObjetivo
@onready var container_funcao = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelFuncao
@onready var container_restricoes = $MainMargin/LayoutPrincipal/PainelEsquerdo/ContainerRestricoes
@onready var btn_selecionar_todos = $MainMargin/LayoutPrincipal/Botoes/UsarTodos
@onready var btn_alternar_tela = $MainMargin/LayoutPrincipal/Botoes/AlternarTela
@onready var painel_inventario = $MainMargin/LayoutPrincipal/PainelDireito/PainelInventario
@onready var painel_criador = $MainMargin/LayoutPrincipal/PainelDireito/PainelCriador
@onready var container_padroes_selecao = $MainMargin/LayoutPrincipal/PainelDireito/PainelInventario/ScrollPadroes/ContainerPadroesSelecao
@onready var container_armas_botoes = $MainMargin/LayoutPrincipal/PainelDireito/PainelCriador/ContainerArmasBotoes
@onready var visualizador_chapa_atual = $MainMargin/LayoutPrincipal/PainelDireito/PainelCriador/PadraoCorte
@onready var info_desperdicio = $MainMargin/LayoutPrincipal/PainelDireito/PainelCriador/InfoDesperdicio

var PYTHON_EXE_PATH: String:
	get:
		if OS.has_feature("editor"):
			return ProjectSettings.globalize_path("res://PythonFiles/resolve_pulp.exe")
		else:
			return OS.get_executable_path().get_base_dir().path_join("PythonFiles/resolve_pulp.exe")

var OUTPUT_FILE_PATH: String:
	get:
		if OS.has_feature("editor"):
			return ProjectSettings.globalize_path("res://PythonFiles/pulp_solution.json")
		else:
			return OS.get_executable_path().get_base_dir().path_join("PythonFiles/pulp_solution.json")

var lista_padroes_disponiveis: Array = []
var padroes_selecionados_indices: Array = []
var valores_demanda_salvos: Dictionary = {} 

var comprimento_acumulado_atual: float = 0.0
var chapa_em_construcao_composicao: Array = []

var _thread: Thread
var _instancia_loading: Control
var visualizando_inventario: bool = true

func _ready() -> void:
	for i in range(Global.pecas_disponiveis.size()):
		valores_demanda_salvos[i] = 0

	_inicializar_criador()
	_gerar_lista_direita_padroes()
	_gerar_restricoes_demanda()
	_atualizar_equacoes_na_tela()
	_atualizar_visibilidade_telas()
	
	Global._verificar_gatilho_tutorial("primeiro_sandbox1")

func _criar_wrapper_peca(peca: Dictionary) -> Control:
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(peca.largura, 50)
	var s = Sprite2D.new()
	s.texture = load(peca.caminho_textura)
	var t_size = s.texture.get_size()
	s.scale = Vector2(peca.largura / t_size.x, 50.0 / t_size.y)
	s.position = Vector2(peca.largura / 2.0, 25)
	wrapper.add_child(s)
	return wrapper

func _alternar_tela_criador_inventario() -> void:
	visualizando_inventario = !visualizando_inventario
	_atualizar_visibilidade_telas()
	
	# Chamadas da função global ao alternar telas
	if not visualizando_inventario:
		Global._verificar_gatilho_tutorial("primeiro_sandbox2")
	else:
		Global._verificar_gatilho_tutorial("primeiro_sandbox3")

func _atualizar_visibilidade_telas() -> void:
	painel_inventario.visible = visualizando_inventario
	painel_criador.visible = !visualizando_inventario

func _inicializar_criador() -> void:
	for child in container_armas_botoes.get_children():
		child.queue_free()
		
	for i in range(Global.pecas_disponiveis.size()):
		var peca = Global.pecas_disponiveis[i]
		var btn_arma = Button.new()
		btn_arma.text = "+ " + peca.nome
		btn_arma.pressed.connect(_adicionar_peca_a_chapa.bind(i))
		container_armas_botoes.add_child(btn_arma)
		
	_limpar_chapa_atual()

func _adicionar_peca_a_chapa(id_peca: int) -> void:
	var peca = Global.pecas_disponiveis[id_peca]
	
	if comprimento_acumulado_atual + peca.largura > Global.tamanho_container:
		info_desperdicio.text = "Não cabe!"
		return
		
	comprimento_acumulado_atual += peca.largura
	chapa_em_construcao_composicao[id_peca] += 1
	
	var container_target = visualizador_chapa_atual.find_child("Visualizador_Padrao", true, false)
	var wrapper = _criar_wrapper_peca(peca)
	container_target.add_child(wrapper)
	
	_atualizar_calculo_desperdicio()

func _atualizar_calculo_desperdicio() -> void:
	var pct = (comprimento_acumulado_atual / Global.tamanho_container) * 100.0
	info_desperdicio.text = "Total da Chapa: %.1f%%" % pct

func _limpar_chapa_atual() -> void:
	var container_target = visualizador_chapa_atual.find_child("Visualizador_Padrao", true, false)

	for child in container_target.get_children():
		child.queue_free()
			
	comprimento_acumulado_atual = 0.0
	chapa_em_construcao_composicao.resize(Global.pecas_disponiveis.size())
	chapa_em_construcao_composicao.fill(0)
	_atualizar_calculo_desperdicio()

func _salvar_padrao_criado() -> void:
	if comprimento_acumulado_atual == 0: return
	
	var novo_padrao = {
		"composicao": chapa_em_construcao_composicao.duplicate()
	}
	
	lista_padroes_disponiveis.append(novo_padrao)
	
	_limpar_chapa_atual()
	_gerar_lista_direita_padroes()
	_gerar_restricoes_demanda()
	_atualizar_equacoes_na_tela()

func _gerar_lista_direita_padroes() -> void:
	for child in container_padroes_selecao.get_children():
		child.queue_free()
	
	var i = 0
	for padrao in lista_padroes_disponiveis:
		var padrao_corte_mod = padrao_corte_model.instantiate()
		var btn_toggle = padrao_corte_mod.find_child("Button", true, false) as Button
		var instancia_visual = padrao_corte_mod.find_child("PadraoCorte", true, false)
		
		btn_toggle.toggle_mode = true
		var is_ativo = padroes_selecionados_indices.has(i)
		btn_toggle.set_pressed_no_signal(is_ativo)
		
		var visualizador = instancia_visual.find_child("Visualizador_Padrao", true, false)
		_desenhar_sprites_no_visualizador(visualizador, padrao.get("composicao", []))
		
		var idx = i
		btn_toggle.toggled.connect(func(is_pressed):
			_alternar_padrao_na_modelagem(idx, is_pressed)
		)
		container_padroes_selecao.add_child(padrao_corte_mod)
		i += 1
		
	_reorganizar_texto_botoes()

func _desenhar_sprites_no_visualizador(container: Node, composicao: Array) -> void:
	for i in range(composicao.size()):
		var qtd = composicao[i]
		var peca = Global.pecas_disponiveis[i]
		for n in range(qtd):
			var wrapper = _criar_wrapper_peca(peca)
			container.add_child(wrapper)

func _alternar_padrao_na_modelagem(idx_padrao: int, is_active: bool) -> void:
	if is_active:
		if not padroes_selecionados_indices.has(idx_padrao):
			var limite_max = lista_padroes_disponiveis.size() if Global.upgrade_todos_padroes_comprado else 5
			if padroes_selecionados_indices.size() < limite_max:
				padroes_selecionados_indices.append(idx_padrao)
			else:
				var item = container_padroes_selecao.get_child(idx_padrao)
				var btn = item.find_child("Button", true, false) as Button
				btn.set_pressed_no_signal(false)
				return
	else:
		padroes_selecionados_indices.erase(idx_padrao)
		
	_gerar_restricoes_demanda()
	_atualizar_equacoes_na_tela()
	_reorganizar_texto_botoes()

func _reorganizar_texto_botoes() -> void:
	var idx_atual = 0
	for item in container_padroes_selecao.get_children():
		var btn = item.find_child("Button", true, false) as Button
		var minia = item.find_child("Miniatura*", true, false)
		
		if btn.is_pressed():
			var posicao_na_equacao = padroes_selecionados_indices.find(idx_atual)
			if posicao_na_equacao != -1:
				btn.text = "Ativo"
				minia.visible = true
				var lbl_num = minia.find_child("Numero", true, false) as Label
				lbl_num.text = str(posicao_na_equacao + 1)
			else:
				btn.set_pressed_no_signal(false)
				minia.visible = false
		else:
			btn.text = "Incluir"
			minia.visible = false
		idx_atual += 1

func _gerar_restricoes_demanda() -> void:
	for child in container_restricoes.get_children():
		child.queue_free()
		
	for i in range(Global.pecas_disponiveis.size()):
		var rest = restricao.instantiate()
		
		var img_peca = rest.find_child("Peca", true, false)
		img_peca.texture = load(Global.pecas_disponiveis[i].caminho_textura)
		
		var input_demanda = rest.find_child("demanda_input", true, false) as LineEdit
		input_demanda.visible = true
		rest.find_child("demanda").visible = false
		input_demanda.text = str(valores_demanda_salvos[i])
		input_demanda.text_changed.connect(func(texto: String):
			var match_res = RegEx.create_from_string("^[0-9]*$").search(texto)
			if match_res:
				input_demanda.text = match_res.get_string()
				valores_demanda_salvos[i] = input_demanda.text.to_int()
			else:
				input_demanda.text = str(valores_demanda_salvos[i])
			input_demanda.caret_column = input_demanda.text.length()
		)
			
		var lbl_tecnica = rest.find_child("Restricao")
		lbl_tecnica.name = "CoeficientesPeca_" + str(i)

		for child in lbl_tecnica.get_children():
			child.queue_free()
			
		var primeiro_termo = true
		for j in range(padroes_selecionados_indices.size()):
			var idx_padrao = padroes_selecionados_indices[j]
			if idx_padrao >= lista_padroes_disponiveis.size(): continue
			
			var padrao = lista_padroes_disponiveis[idx_padrao]
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
				var lbl_mais = Label.new()
				lbl_mais.text = "    +"
				lbl_mais.add_theme_font_size_override("font_size", 18)
				container_funcao.add_child(lbl_mais)
			var minia = miniatura.instantiate()
			container_funcao.add_child(minia)
			minia.find_child("Numero").text = str(i + 1)

func _on_btn_selecionar_todos_pressed() -> void:
	if not Global.upgrade_todos_padroes_comprado: return
	
	padroes_selecionados_indices.clear()
	for i in range(lista_padroes_disponiveis.size()):
		padroes_selecionados_indices.append(i)
		
	_gerar_restricoes_demanda()
	_atualizar_equacoes_na_tela()
	_reorganizar_texto_botoes()
	_on_btn_resolver_pressed()

func _on_btn_resolver_pressed() -> void:
	if padroes_selecionados_indices.is_empty(): return
		
	var composicoes_enviadas = []
	for idx in padroes_selecionados_indices:
		var padrao = lista_padroes_disponiveis[idx]
		composicoes_enviadas.append(padrao.get("composicao", []))
		
	var matriz_demanda_manual = []
	matriz_demanda_manual.resize(Global.pecas_disponiveis.size())
	matriz_demanda_manual.fill(0)
	
	for i in range(Global.pecas_disponiveis.size()):
		matriz_demanda_manual[i] = valores_demanda_salvos[i]

	var args: Array[String] = []
	args.append(str(matriz_demanda_manual))
	for comp in composicoes_enviadas:
		args.append(str(comp))

	_instancia_loading = cena_loading_preload.instantiate()
	get_tree().root.add_child(_instancia_loading)

	_thread = Thread.new()
	_thread.start(_executar_solver_thread.bind(args))

func _executar_solver_thread(args: Array) -> void:
	var saida_terminal = []
	var resultado_codigo = OS.execute(PYTHON_EXE_PATH, args, saida_terminal, true)
	call_deferred("_finalizar_processamento", resultado_codigo)

func _finalizar_processamento(resultado_codigo: int) -> void:
	_thread.wait_to_finish()
	_instancia_loading.queue_free()

	if resultado_codigo == 0:
		if FileAccess.file_exists(OUTPUT_FILE_PATH):
			var file = FileAccess.open(OUTPUT_FILE_PATH, FileAccess.READ)
			var resultado = JSON.parse_string(file.get_as_text())
			file.close()
			
			if resultado and resultado.get("status") == "Optimal":
				var solucao_lista = resultado.get("solucao", [])
				var total_chapas = resultado.get("chapas_usadas", 0)
				
				var texto_cortes = ""
				for j in range(solucao_lista.size()):
					var qtd_cortes = int(solucao_lista[j])
					if qtd_cortes > 0:
						texto_cortes += "Padrão %d: %d vez(es)\n" % [(j + 1), qtd_cortes]
				
				var texto_total = "Total de Chapas Utilizadas: %d" % total_chapas
				_exibir_popup_resultado(texto_cortes, texto_total)
			else:
				_exibir_popup_resultado("Aviso", "Inviável: Os padrões criados não conseguem suprir a demanda digitada.")
	else:
		_exibir_popup_resultado("Erro na execução do solver externo.", "")

func _exibir_popup_resultado(texto_label1: String, texto_label2: String) -> void:
	var mostra_corte = cena_mostra_cortes.instantiate()
	add_child(mostra_corte)
	
	var lbl1 = mostra_corte.find_child("Label1", true, false) as Label
	var lbl2 = mostra_corte.find_child("Label2", true, false) as Label
	var btn_continuar = mostra_corte.find_child("Continuar", true, false) as Button
	
	lbl1.text = texto_label1
	lbl2.text = texto_label2
	lbl2.visible = not texto_label2.is_empty()
	btn_continuar.pressed.connect(func(): mostra_corte.queue_free())

func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
