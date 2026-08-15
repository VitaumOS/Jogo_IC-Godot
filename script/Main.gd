extends Node2D

@export var cena_linha_padrao: PackedScene
@export var cena_resultado_dinheiro: PackedScene

# --- REFERÊNCIAS DE NÓS ---
@onready var vbox_padroes_lista = $UI/ScrollContainer/PadraoCorteSalvo
@onready var popup = $PopUp
@onready var contrato_visualizacao = $UI/Contrato_visualizacao

# --- VARIÁVEIS DE LÓGICA ---
var padroes_corte_salvos_valor: Array = [] 
var demanda: Array = []
var pecas_disponiveis: Array = Global.pecas_disponiveis

var thread_pulp: Thread

var PYTHON_EXE_PATH: String:
	get:
		if OS.has_feature("editor"):
			return ProjectSettings.globalize_path("res://PythonFiles/resolve_pulp.exe")
		else:
			return OS.get_executable_path().get_base_dir().path_join("PythonFiles/resolve_pulp.exe")

var OUTPUT_FILE_NAME: String:
	get:
		if OS.has_feature("editor"):
			return ProjectSettings.globalize_path("res://PythonFiles/pulp_solution.json")
		else:
			return OS.get_executable_path().get_base_dir().path_join("PythonFiles/pulp_solution.json")

func _ready():
	add_to_group("main_logic")
	demanda = Global.contrato_ativo.demanda if Global.contrato_ativo else [0,0,0,0,0,0]
	_carregar_padroes_da_loja()
	contrato_visualizacao.inicializar(demanda, vbox_padroes_lista, padroes_corte_salvos_valor)
	if Global.ultimo_desempenho_ritmo < 0:
		_verificar_dialogo_diario()
	else:
		_finalizar_logica_pulp()
		
	$UI/VBoxContainer/Modelagem.visible = Global.dia_atual > 4
		
	if Global.contrato_ativo:
		if !Global.finalizou_tutorial_primeiro_contrato:
			if !Global.padroes_desbloqueados.is_empty():
				Global._verificar_gatilho_tutorial("primeiro_contrato_escolhido1")
			else:
				Global._verificar_gatilho_tutorial("primeiro_contrato_escolhido2")	
			Global.finalizou_tutorial_primeiro_contrato = true
		contrato_visualizacao.atualizar()
		
	_conectar_sinais_botoes_quantidade()
	_atualizar_pintura_demanda()

func _atualizar_pintura_demanda():
	contrato_visualizacao._atualizar_pintura_demanda()

# Monitora e conecta os botões de mais e menos de cada padrão de corte da lista
func _conectar_sinais_botoes_quantidade():
	await get_tree().process_frame
	for linha in vbox_padroes_lista.get_children():
		var btn_mais = linha.find_child("btnMais") as Button
		var btn_menos = linha.find_child("btnMenos") as Button
		if btn_mais and !btn_mais.is_connected("pressed", _atualizar_pintura_demanda):
			btn_mais.pressed.connect(_atualizar_pintura_demanda)
		if btn_menos and !btn_menos.is_connected("pressed", _atualizar_pintura_demanda):
			btn_menos.pressed.connect(_atualizar_pintura_demanda)
			
		linha.find_child("Perda").visible = (!Global.dia_atual == 1)

func _verificar_dialogo_diario():
	if Global.deve_exibir_dialogo_do_dia():
		var todos_dialogos = _carregar_json("res://data_json/dialogos.json")
		var dia_str = str(Global.dia_atual)
		
		if todos_dialogos.has(dia_str):
			var falas_do_dia = todos_dialogos[dia_str]
			if has_node("/root/Dialogo"):
				for fala in falas_do_dia:
					if fala.has("retrato") and fala["retrato"] is String:
						fala["retrato"] = load(fala["retrato"])
				Dialogo.iniciar_dialogo(falas_do_dia)

# Função auxiliar de carregamento
func _carregar_json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho): return {}
	var arquivo = FileAccess.open(caminho, FileAccess.READ)
	return JSON.parse_string(arquivo.get_as_text())

func _carregar_padroes_da_loja():
	for c in vbox_padroes_lista.get_children(): 
		c.queue_free()
	
	padroes_corte_salvos_valor.clear()
	for item in Global.padroes_desbloqueados:
		_exibir_padrao_na_lista(item)
	
	if Global.padroes_desbloqueados.size() > 8:
		var item_vazio: Dictionary = {"dia": 0, "nome": "", "composicao": [0, 0, 0, 0, 0, 0], "preco": 0}
		_exibir_padrao_na_lista(item_vazio)

func _exibir_padrao_na_lista(item: Dictionary):
	var pecas_data = []
	for i in item.composicao.size():
		var qtd = item.composicao[i]
		for n in qtd:
			box_pecas_data_append(pecas_data, i)
	item["pecas"] = pecas_data
	var linha = cena_linha_padrao.instantiate()
	
	linha.set_meta("composicao", item.composicao)
	
	vbox_padroes_lista.add_child(linha)
	linha.configurar(item)
	padroes_corte_salvos_valor.append(item.composicao)

func box_pecas_data_append(arr: Array, i: int):
	arr.append({
		"largura_peca": Global.pecas_disponiveis[i].largura,
		"caminho_textura": Global.pecas_disponiveis[i].caminho_textura
	})

func verifica_cortes_usuario() -> bool:
	var total = [0, 0, 0, 0, 0, 0]
	var itens_da_lista = vbox_padroes_lista.get_children()
	
	var lines_validas = itens_da_lista.filter(func(n): return n.has_method("get_quantidade") and not n.is_queued_for_deletion())
	
	for i in range(lines_validas.size()):
		var linha = lines_validas[i]
		var qtd = linha.get_quantidade()
		var composicao = padroes_corte_salvos_valor[i]
		
		for j in range(composicao.size()):
			total[j] += composicao[j] * qtd
			
	for i in range(demanda.size()):
		if total[i] < demanda[i]: return false
	return true

func get_total_chapas_usadas() -> int:
	var soma = 0
	for linha in vbox_padroes_lista.get_children():
		if linha.has_method("get_quantidade") and not linha.is_queued_for_deletion():
			soma += linha.get_quantidade()
	return soma

func _on_bater_martelo_pressed():
	popup.mostrar_confirmacao("Deseja iniciar o corte?")
	var confirma = await popup.resposta 
	
	if confirma:
		if !verifica_cortes_usuario():
			popup.mostrar_mensagem_erro("Os cortes não atenderam a demanda!")
			return
		elif Global.contrato_ativo == null:
			popup.mostrar_mensagem_erro("Nenhum contrato foi solicitado!")
			return
		elif get_total_chapas_usadas() > Global.estoque_chapas:
			popup.mostrar_mensagem_erro("Chapas insuficientes!")
			return
		_preparar_e_iniciar_forja()

func _preparar_e_iniciar_forja():
	var lista_para_forjar = []
	var itens_da_lista = vbox_padroes_lista.get_children().filter(func(n): return n.has_method("get_quantidade") and not n.is_queued_for_deletion())
	
	for i in range(itens_da_lista.size()):
		var qtd = itens_da_lista[i].get_quantidade()
		if qtd > 0:
			var composicao = padroes_corte_salvos_valor[i]
			for p_idx in range(composicao.size()):
				for n in range(composicao[p_idx] * qtd):
					lista_para_forjar.append(pecas_disponiveis[p_idx].nome)

	Global.armas_na_esteira_atual = lista_para_forjar
	Global.chapas_usadas_pelo_jogador = get_total_chapas_usadas()
	
	var args_pulp: Array[String] = [str(demanda)]
	for p in padroes_corte_salvos_valor: 
		args_pulp.append(str(p))
	
	thread_pulp = Thread.new()
	thread_pulp.start(_executar_pulp_em_background.bind(args_pulp))
	
	get_tree().change_scene_to_file("res://scene/Forja_Ritmo.tscn")

func _executar_pulp_em_background(args: Array[String]):
	var saida_terminal = []
	OS.execute(PYTHON_EXE_PATH, args, saida_terminal, true)

func _finalizar_logica_pulp():
	var z_user = Global.chapas_usadas_pelo_jogador
	if Global.estoque_chapas < z_user:
		_limpar_dados_transicao()
		return
		
	if thread_pulp and thread_pulp.is_alive():
		thread_pulp.wait_to_finish()
	thread_pulp = null

	# Lê o arquivo que a Thread gerou durante o jogo de ritmo
	if FileAccess.file_exists(OUTPUT_FILE_NAME):
		var arquivo = FileAccess.open(OUTPUT_FILE_NAME, FileAccess.READ)
		var res = JSON.parse_string(arquivo.get_as_text())
		
		if res and res.get("status") == "Optimal":
			var z_pulp = res["chapas_usadas"]
			var alcancou_minimo = z_user <= z_pulp
			Global.estoque_chapas -= z_user
			Global.registrar_contrato_concluido(Global.contrato_ativo)
			Global.completar_contrato(alcancou_minimo, Global.ultimo_desempenho_ritmo)
			
			var tela_dinheiro = cena_resultado_dinheiro.instantiate()
			$UI.add_child(tela_dinheiro)
			var texto_minimo = tela_dinheiro.get_node("PanelContainer/VBox/VboxTexto/Label3")
			texto_minimo.text = "Alcançou o mínimo: " + ("SIM (+20%)" if alcancou_minimo else "NÃO")
			var cor_resultado = Color.GREEN if alcancou_minimo else Color.RED
			texto_minimo.add_theme_color_override("font_color", cor_resultado)
			
			if alcancou_minimo and !Global.alcancou_primeiro_minimo:
				Global.alcancou_primeiro_minimo = true
				Global._verificar_gatilho_tutorial("primeiro_minimo")
			
			await tela_dinheiro.find_child("Continuar").pressed
			tela_dinheiro.queue_free()
			$UI/Info.atualizar()

	if !Global.finalizou_primeiro_contrato:
		Global.finalizou_primeiro_contrato = true
		Global._verificar_gatilho_tutorial("primeiro_contrato_concluido")
	
	if Global.todos_contratos_concluidos():
		Global._verificar_gatilho_tutorial("todos_contratos_concluidos")
		
	if Global.todos_contratos_concluidos() and Global.dia_atual==1:
		Global._verificar_gatilho_tutorial("todos_contratos_concluidos_dia1")

	_limpar_dados_transicao()

func _limpar_dados_transicao():
	Global.armas_na_esteira_atual = []
	Global.ultimo_desempenho_ritmo = -1.0

func _on_modelagem_pressed():
	if Global.dia_atual == 5 and !Global.finalizou_treino:
		get_tree().change_scene_to_file("res://scene/TreinoModelagem.tscn")
	else:
		get_tree().change_scene_to_file("res://scene/ModelagemMatematica.tscn")
