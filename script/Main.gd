# Main.gd
extends Node2D

# Cenas Exportadas
@export var cena_botao_ui: PackedScene
@export var cena_padrao_corte: PackedScene

#Variáveis de Nodes
@onready var label_timer = $UI/Topo/TimerPanel
@onready var label_dia = $UI/Topo/DiaPanel
@onready var label_dinheiro = $UI/Topo/DinheiroPanel
@onready var btn_contrato_grande = $UI/CorpoCentral/LadoEsquerdo/BotaoContratoGrande
@onready var vbox_padroes_lista = $UI/CorpoCentral/LadoDireito/ScrollContainer/PadraoCorteSalvo
@onready var rotulo_feedback = $UI/FeedbackLabel
@onready var btn_resolver = $UI/Rodape/BtnResolver
@onready var btn_loja = $UI/Rodape/BtnLoja
@onready var btn_sair = $UI/Rodape/BtnSair

# Variáveis de Lógica
var largura_container: float
var padroes_corte_salvos: Array = [] 
var padroes_corte_salvos_valor: Array = [] 
var padroes_selecionados: Array = [] 
var text_edits_padroes: Array[TextEdit] = []

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

func _process(delta):
	if Global.tempo_restante > 0:
		Global.tempo_restante -= delta
		_atualizar_ui_timer()
	else: 
		get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn")

#UI E NAVEGAÇÃO
func _configurar_botoes_fixos():
	
	# Botão Resolver
	btn_resolver.text = "🔨 BATER O FERRO\n(Resolver PCU)"
	if not btn_resolver.pressed.is_connected(_resolver_pcu):
		btn_resolver.pressed.connect(_resolver_pcu)
	
	# Botão Loja
	btn_loja.text = "🏪 IR À LOJA"
	btn_loja.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Cena_Loja.tscn"))
	
	# Botão Sair
	btn_sair.text = "🚪 ENCERRAR DIA"
	btn_sair.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn"))
	
	# Botão de Contrato
	btn_contrato_grande.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Cena_contratos.tscn"))

func _atualizar_ui_timer():
	var min = int(Global.tempo_restante) / 60
	var seg = int(Global.tempo_restante) % 60
	label_timer.text = "⌛ %02d:%02d" % [min, seg]

func _atualizar_ui_estatica():
	label_dia.text = "📅 DIA: %d" % Global.dia_atual
	label_dinheiro.text = "💰 R$ %d" % Global.dinheiro

func _atualizar_display_contrato():
	if not Global.contrato_ativo:
		btn_contrato_grande.text = "MURAL DE CONTRATOS"
		return
	var txt = "📜 %s\n\nDEMANDA:\n" % Global.contrato_ativo.nome
	#mostra apenas as peças a serem cortadas
	for i in demanda.size():
		if demanda[i] > 0:
			txt += "- %s: %d\n" % [pecas_disponiveis[i].nome, demanda[i]]
	btn_contrato_grande.text = txt

func _carregar_padroes_da_loja():
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
			pecas_data.append({"largura_peca": Global.pecas_disponiveis[i].largura, "caminho_textura": Global.pecas_disponiveis[i].caminho_textura})
	
	var dados = {"largura": largura_ocupada, "eficiencia": (largura_ocupada / largura_container) * 100.0, 
				 "pecas": pecas_data, "nome": nome_customizado, "composicao": padrao_numerico}
	
	padroes_corte_salvos_valor.append(padrao_numerico)
	padroes_corte_salvos.append(dados)
	padroes_selecionados.append(padroes_corte_salvos.size() - 1)
	_exibir_padrao_na_lista(dados)

func _exibir_padrao_na_lista(dados: Dictionary):
	var h_linha = HBoxContainer.new()
	h_linha.custom_minimum_size.y = 40
	h_linha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Instancia o visual
	var visual = cena_padrao_corte.instantiate()
	visual.custom_minimum_size = Vector2(500, 50) # Define um tamanho base
	var bg:ColorRect = visual.get_node("Background")
	bg.custom_minimum_size = Vector2(500,50)
	
	# Atualiza o texto e as peças
	visual.get_node("Label").text = "%s (%.1f%%)" % [dados.nome, dados.eficiencia]
	var container_pecas = visual.get_node("Visualizador_Padrao")
	
	for p in dados.pecas:
		var w = Control.new(); w.custom_minimum_size = Vector2(p.largura_peca, 30)
		var s = Sprite2D.new(); s.texture = load(p.caminho_textura)
		if s.texture:
			s.scale = Vector2(p.largura_peca / s.texture.get_size().x, 0.6)
			s.position = Vector2(p.largura_peca / 2.0, 25)
		w.add_child(s)
		container_pecas.add_child(w)

	# Lado do Input
	var v_input = VBoxContainer.new()
	v_input.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl = Label.new(); lbl.text = "Qtd:"
	var input = TextEdit.new()
	input.custom_minimum_size = Vector2(80, 30)
	input.text = "0"
	text_edits_padroes.append(input)
	
	v_input.add_child(lbl)
	v_input.add_child(input)
	h_linha.add_child(visual)
	h_linha.add_child(v_input)
	
	# Adiciona a linha ao container que está no Scroll
	vbox_padroes_lista.add_child(h_linha)
	var spc = Control.new(); spc.custom_minimum_size.y = 20
	vbox_padroes_lista.add_child(spc)

func verifica_cortes_usuario() -> bool:
	var total = [0,0,0,0,0,0]
	for i in text_edits_padroes.size():
		var qtd = text_edits_padroes[i].text.to_int()
		for j in padroes_corte_salvos_valor[i].size(): 
			total[j] += padroes_corte_salvos_valor[i][j] * qtd
	for i in demanda.size():
		if total[i] < demanda[i]: return false
	return true

func get_total_chapas_usadas() -> int:
	var s = 0
	for te in text_edits_padroes: s += te.text.to_int()
	return s

func _resolver_pcu():
	if Global.contrato_ativo == null or !verifica_cortes_usuario():
		_atualizar_texto_resultado("Erro: Cortes insuficientes para a demanda!")
		return

	var args = [PYTHON_SCRIPT, str(demanda)]
	for idx in padroes_selecionados: args.append(str(padroes_corte_salvos_valor[idx]))
	
	if OS.execute(PYTHON_PATH, args) == 0:
		var res = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT_FILE_NAME))
		if res and res.get("status") == "Optimal":
			var z_pulp = res["chapas_usadas"]
			var z_user = get_total_chapas_usadas()
			var rec = Global.contrato_ativo.recompensa
			var bonus = false
			
			if z_user <= z_pulp:
				rec = int(rec * 1.2)
				bonus = true
				_atualizar_texto_resultado("PERFEITO! BÔNUS DE 20%%\nTotal Gasto: %d chapas" % z_user)
			else:
				_atualizar_texto_resultado("CONCLUÍDO!\nSeu gasto: %d | Mínimo IA: %d" % [z_user, z_pulp])
			
			Global.completar_contrato(bonus)
			_atualizar_ui_estatica()
			_atualizar_display_contrato()

func _atualizar_texto_resultado(msg: String):
	rotulo_feedback.text = msg
