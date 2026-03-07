# Main.gd
extends Node2D

# Cenas Exportadas
@export var cena_padrao_corte: PackedScene

# Variáveis de Nodes
@onready var label_dia = $UI/Topo/DiaPanel
@onready var label_dinheiro = $UI/Topo/DinheiroPanel
@onready var btn_contrato_grande = $UI/Controle_Corpo/CorpoCentral/LadoEsquerdo/BotaoContratoGrande
@onready var vbox_padroes_lista = $UI/Controle_Corpo/CorpoCentral/LadoDireito/ScrollContainer/PadraoCorteSalvo
@onready var lbl_estoque_chapas = $UI/Topo/LabelQuantidade
@onready var rotulo_feedback = $UI/FeedbackLabel
@onready var btn_resolver = $UI/Rodape/BtnResolver
@onready var btn_loja = $UI/Rodape/BtnLoja
@onready var btn_sair = $UI/Rodape/BtnSair

# Variáveis de Lógica
var largura_container: float
var padroes_corte_salvos: Array = [] 
var padroes_corte_salvos_valor: Array = [] 
var padroes_selecionados: Array = [] 
var labels_qtd_referencia: Array[Label] = [] 

var PYTHON_PATH = ProjectSettings.globalize_path("res://PythonFiles/venv/Scripts/python.exe")
var PYTHON_SCRIPT = ProjectSettings.globalize_path("res://PythonFiles/resolve_pcu_pl.py")
const OUTPUT_FILE_NAME = "res://pulp_solution.json" 

var demanda: Array = [0, 0, 0, 0, 0, 0]
var pecas_disponiveis: Array = Global.pecas_disponiveis

func _ready():
	add_to_group("main_logic")
	largura_container = Global.tamanho_container
	
	demanda = Global.contrato_ativo.demanda if Global.contrato_ativo else [0,0,0,0,0,0]
	
	_carregar_padroes_da_loja()
	_configurar_botoes_fixos()
	_atualizar_ui_estatica()
	_atualizar_display_contrato()
	if Global.ultimo_desempenho_ritmo >= 0:
		_finalizar_logica_pulp()

func _atualizar_display_estoque():
	$UI/IconeChapa/LabelQtd.text = str(Global.estoque_chapas_extras)
	

func _configurar_botoes_fixos():
	if not btn_resolver.pressed.is_connected(_resolver_pcu):
		btn_resolver.pressed.connect(_resolver_pcu)
	if not btn_loja.pressed.is_connected(_on_loja_pressed):
		btn_loja.pressed.connect(_on_loja_pressed)
	if not btn_sair.pressed.is_connected(_on_sair_pressed):
		btn_sair.pressed.connect(_on_sair_pressed)
	if not btn_contrato_grande.pressed.is_connected(_on_contrato_pressed):
		btn_contrato_grande.pressed.connect(_on_contrato_pressed)
		
func _on_loja_pressed(): get_tree().change_scene_to_file("res://scene/Cena_Loja.tscn")
func _on_sair_pressed(): get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn")
func _on_contrato_pressed(): get_tree().change_scene_to_file("res://scene/Cena_contratos.tscn")
	
func _atualizar_ui_estatica():
	label_dia.text = "DIA: %d" % Global.dia_atual
	label_dinheiro.text = "R$ %d" % Global.dinheiro
	lbl_estoque_chapas.text = "Chapas: %d" % Global.estoque_chapas_extras

func _atualizar_display_contrato():
	if not Global.contrato_ativo:
		btn_contrato_grande.text = "MURAL DE \nCONTRATOS"
		return
	var txt = "%s\n\nDEMANDA:\n" % Global.contrato_ativo.nome
	for i in demanda.size():
		if demanda[i] > 0:
			txt += "- %s: %d\n" % [pecas_disponiveis[i].nome, demanda[i]]
	btn_contrato_grande.text = txt

func _carregar_padroes_da_loja():
	for c in vbox_padroes_lista.get_children(): c.queue_free()
	labels_qtd_referencia.clear()
	for item in Global.padroes_desbloqueados:
		if not padroes_corte_salvos.any(func(p): return p.nome == item.nome):
			_registrar_novo_padrao(item.composicao, item.nome)

func _registrar_novo_padrao(padrao_numerico: Array, nome_customizado: String):
	var largura_ocupada = 0.0
	var pecas_data = []
	
	for i in Global.pecas_disponiveis.size():
		var qtd = padrao_numerico[i] if i < padrao_numerico.size() else 0
		largura_ocupada += Global.pecas_disponiveis[i].largura * qtd
		for n in qtd: 
			pecas_data.append({
				"largura_peca": Global.pecas_disponiveis[i].largura, 
				"caminho_textura": Global.pecas_disponiveis[i].caminho_textura
			})
	
	var dados = {
		"largura": largura_ocupada, 
		"eficiencia": (largura_ocupada / largura_container) * 100.0, 
		"pecas": pecas_data, 
		"nome": nome_customizado, 
		"composicao": padrao_numerico
	}
	padroes_corte_salvos_valor.append(padrao_numerico)
	padroes_corte_salvos.append(dados)
	padroes_selecionados.append(padroes_corte_salvos.size() - 1)
	_exibir_padrao_na_lista(dados)

func _exibir_padrao_na_lista(dados: Dictionary):
	var h_linha = HBoxContainer.new()
	h_linha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var visual = cena_padrao_corte.instantiate()
	visual.custom_minimum_size = Vector2(550, 50)

	var container_pecas = visual.get_node("Visualizador_Padrao")
	for p in dados.pecas:
		var w = Control.new(); w.custom_minimum_size = Vector2(p.largura_peca, 10)
		var s = Sprite2D.new(); s.texture = load(p.caminho_textura)
		if s.texture:
			s.scale = Vector2(p.largura_peca / s.texture.get_size().x, 0.6)
			s.position = Vector2(p.largura_peca / 2.0, 25)
		w.add_child(s)
		container_pecas.add_child(w)

	var v_selecao = VBoxContainer.new()
	v_selecao.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl_titulo = Label.new(); lbl_titulo.text = "Quantidade"; lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER 
	lbl_titulo.add_theme_font_size_override("font_size", 12)
	var h_controles = HBoxContainer.new(); h_controles.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn_menos = Button.new(); btn_menos.text = " - "; btn_menos.custom_minimum_size = Vector2(25, 25)
	var btn_mais = Button.new(); btn_mais.text = " + "; btn_mais.custom_minimum_size = Vector2(25, 25)
	var lbl_qtd = Label.new(); lbl_qtd.text = "0"; lbl_qtd.custom_minimum_size = Vector2(25, 0)
	lbl_qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	labels_qtd_referencia.append(lbl_qtd) 

	btn_menos.pressed.connect(func(): if int(lbl_qtd.text) > 0: lbl_qtd.text = str(int(lbl_qtd.text) - 1))
	btn_mais.pressed.connect(func(): lbl_qtd.text = str(int(lbl_qtd.text) + 1))
	
	h_controles.add_child(btn_menos); h_controles.add_child(lbl_qtd); h_controles.add_child(btn_mais)
	v_selecao.add_child(lbl_titulo); v_selecao.add_child(h_controles)
	v_selecao.position = Vector2(-100,0)
	
	h_linha.add_child(visual); h_linha.add_child(v_selecao)
	vbox_padroes_lista.add_child(h_linha)
	
	var spc = Control.new(); spc.custom_minimum_size.y = 10
	vbox_padroes_lista.add_child(spc)

func verifica_cortes_usuario() -> bool:
	var total = [0, 0, 0, 0, 0, 0]
	for i in labels_qtd_referencia.size():
		var qtd = int(labels_qtd_referencia[i].text)
		for j in padroes_corte_salvos_valor[i].size(): 
			total[j] += padroes_corte_salvos_valor[i][j] * qtd
	for i in demanda.size():
		if total[i] < demanda[i]: return false
	return true

func get_total_chapas_usadas() -> int:
	var s = 0
	for lbl in labels_qtd_referencia: s += int(lbl.text)
	return s

func _resolver_pcu():
	if Global.contrato_ativo == null or !verifica_cortes_usuario():
		_atualizar_texto_resultado("Erro: Cortes insuficientes!")
		return

	var lista_para_forjar = []
	for i in range(labels_qtd_referencia.size()):
		var qtd_chapas = int(labels_qtd_referencia[i].text)
		if qtd_chapas > 0:
			var composicao = padroes_corte_salvos_valor[i]
			for peca_idx in range(composicao.size()):
				for n in range(composicao[peca_idx] * qtd_chapas):
					lista_para_forjar.append(pecas_disponiveis[peca_idx].nome)

	Global.armas_na_esteira_atual = lista_para_forjar
	Global.chapas_usadas_pelo_jogador = get_total_chapas_usadas()
	
	get_tree().change_scene_to_file("res://scene/Forja_Ritmo.tscn")

func _finalizar_logica_pulp():
	var args = [PYTHON_SCRIPT, str(demanda)]
	for padrao in padroes_corte_salvos_valor:
		args.append(str(padrao))
	
	var z_user = Global.chapas_usadas_pelo_jogador
	
	if Global.estoque_chapas_extras < z_user:
		_atualizar_texto_resultado("FALHA: Você não tem chapas suficientes!")
		_limpar_dados_transicao()
		return

	#Executa o Solver Python (PuLP)
	if OS.execute(PYTHON_PATH, args) == 0:
		var arquivo = FileAccess.open(OUTPUT_FILE_NAME, FileAccess.READ)
		var res = JSON.parse_string(arquivo.get_as_text())
		
		if res and res.get("status") == "Optimal":
			var z_pulp = res["chapas_usadas"]
			
			Global.estoque_chapas_extras -= z_user
		
			var otimizou = (z_user <= z_pulp)
			var ritmo = Global.ultimo_desempenho_ritmo
			Global.registrar_contrato_concluido(Global.contrato_ativo)
			Global.completar_contrato(otimizou, ritmo)
			
			if otimizou and ritmo==1.0:
				_atualizar_texto_resultado("PERFEITO! Usou o mínimo e teve batida perfeita! Ganhou: R$%.2f" %[Global.recompensa_final])
			elif !otimizou:
				_atualizar_texto_resultado("CONCLUÍDO. Gastou %d chapas. Mínimo necessário:%d. Ganhou: R$%.2f" % [z_user, z_pulp, Global.recompensa_final])
			else:
				_atualizar_texto_resultado("CONCLUÍDO! Ganhou: R$%.2f" %[Global.recompensa_final])
			
	_limpar_dados_transicao()

# Função auxiliar para manter o código limpo
func _limpar_dados_transicao():
	Global.armas_na_esteira_atual = []
	Global.ultimo_desempenho_ritmo = -1.0
	_atualizar_ui_estatica()
	_atualizar_display_contrato()

func _atualizar_texto_resultado(msg: String):
	rotulo_feedback.text = msg
