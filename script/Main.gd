extends Node2D


@export var cena_linha_padrao: PackedScene

# --- REFERÊNCIAS DE NÓS ---
@onready var vbox_padroes_lista = $UI/Controle_Corpo/CorpoCentral/LadoDireito/ScrollContainer/PadraoCorteSalvo
@onready var label_dia = $UI/Topo/DiaPanel
@onready var label_dinheiro = $UI/Topo/DinheiroPanel
@onready var lbl_estoque_chapas = $UI/Topo/LabelQuantidade
@onready var btn_contrato_visual = $UI/Controle_Corpo/CorpoCentral/LadoEsquerdo/BotaoContratoGrande
@onready var popup = $PopUp

# --- VARIÁVEIS DE LÓGICA ---
var padroes_corte_salvos_valor: Array = [] 
var demanda: Array = []
var pecas_disponiveis: Array = Global.pecas_disponiveis

var PYTHON_PATH = ProjectSettings.globalize_path("res://PythonFiles/venv/Scripts/python.exe")
var PYTHON_SCRIPT = ProjectSettings.globalize_path("res://PythonFiles/resolve_pcu_pl.py")
const OUTPUT_FILE_NAME = "res://pulp_solution.json"

func _ready():
	add_to_group("main_logic")
	demanda = Global.contrato_ativo.demanda if Global.contrato_ativo else [0,0,0,0,0,0]
	_carregar_padroes_da_loja()
	_atualizar_ui_estatica()
	_atualizar_display_contrato()
	
	if Global.ultimo_desempenho_ritmo < 0:
		_verificar_dialogo_diario()
	else:
		_finalizar_logica_pulp()

func _verificar_dialogo_diario():
	if Global.deve_exibir_dialogo_do_dia():
		var todos_dialogos = _carregar_json("res://data_json/dialogos.json")
		var dia_str = str(Global.dia_atual)
		
		if todos_dialogos.has(dia_str):
			var falas_do_dia = todos_dialogos[dia_str]
			if has_node("/root/Dialogo"):
				for fala in falas_do_dia:
					if fala.has("retrato"):
						fala["retrato"] = load(fala["retrato"])
				Dialogo.iniciar_dialogo(falas_do_dia)

# Função auxiliar de carregamento (caso não tenha no Main, pode usar a do Global)
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

func _exibir_padrao_na_lista(item: Dictionary):
	var pecas_data = []
	for i in item.composicao.size():
		var qtd = item.composicao[i]
		for n in qtd:
			pecas_data.append({
				"largura_peca": Global.pecas_disponiveis[i].largura,
				"caminho_textura": Global.pecas_disponiveis[i].caminho_textura
			})
	item["pecas"] = pecas_data
	var linha = cena_linha_padrao.instantiate()
	vbox_padroes_lista.add_child(linha)
	linha.configurar(item)
	
	padroes_corte_salvos_valor.append(item.composicao)

func verifica_cortes_usuario() -> bool:
	var total = [0, 0, 0, 0, 0, 0]
	var itens_da_lista = vbox_padroes_lista.get_children()
	
	var linhas_validas = itens_da_lista.filter(func(n): return n.has_method("get_quantidade") and not n.is_queued_for_deletion())
	
	for i in range(linhas_validas.size()):
		var linha = linhas_validas[i]
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

func _on_resolver_pressed():
	popup.mostrar_confirmacao("Deseja iniciar o corte?")
	var confirma = await popup.resposta 
	
	if confirma:
		if !verifica_cortes_usuario():
			popup.mostrar_mensagem_erro("Cortes insuficientes!")
			return
		elif Global.contrato_ativo == null:
			popup.mostrar_mensagem_erro("Nenhum contrato foi solicitado!")
			return
		elif get_total_chapas_usadas()>Global.estoque_chapas:
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
	get_tree().change_scene_to_file("res://scene/Forja_Ritmo.tscn")

func _atualizar_ui_estatica():
	label_dia.text = "DIA: %d" % Global.dia_atual
	label_dinheiro.text = "R$ %d" % Global.dinheiro
	lbl_estoque_chapas.text = "Chapas: %d" % Global.estoque_chapas

func _atualizar_display_contrato():
	if not Global.contrato_ativo:
		btn_contrato_visual.text = "MURAL DE \nCONTRATOS"
		return
	var txt = "%s\n\nDEMANDA:\n" % Global.contrato_ativo.nome
	for i in demanda.size():
		if demanda[i] > 0:
			txt += "- %s: %d\n" % [pecas_disponiveis[i].nome, demanda[i]]
	btn_contrato_visual.text = txt

func _finalizar_logica_pulp():
	var z_user = Global.chapas_usadas_pelo_jogador
	if Global.estoque_chapas < z_user:
		_limpar_dados_transicao()
		return

	var args = [PYTHON_SCRIPT, str(demanda)]
	for p in padroes_corte_salvos_valor: args.append(str(p))
	
	if OS.execute(PYTHON_PATH, args) == 0:
		var arquivo = FileAccess.open(OUTPUT_FILE_NAME, FileAccess.READ)
		var res = JSON.parse_string(arquivo.get_as_text())
		if res and res.get("status") == "Optimal":
			var z_pulp = res["chapas_usadas"]
			Global.estoque_chapas -= z_user
			Global.registrar_contrato_concluido(Global.contrato_ativo)
			Global.completar_contrato(z_user <= z_pulp, Global.ultimo_desempenho_ritmo)
			popup.mostrar_conclusao_contrato()

	_limpar_dados_transicao()

func _limpar_dados_transicao():
	Global.armas_na_esteira_atual = []
	Global.ultimo_desempenho_ritmo = -1.0
	_atualizar_ui_estatica()
	_atualizar_display_contrato()

func _on_loja_pressed(): get_tree().change_scene_to_file("res://scene/Cena_Loja.tscn")
func _on_sair_pressed(): get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn")
func _on_contrato_pressed(): get_tree().change_scene_to_file("res://scene/Cena_contratos.tscn")
