extends Node2D

@onready var container_chapa = $VBoxContainer/ContainerChapa
@onready var container_excesso = $VBoxContainer/ContainerExcesso
@onready var vbox_container = $VBoxContainer
@onready var tooltip_armas = $TooltipArmas
@onready var label_tooltip = $TooltipArmas/Label
@onready var lbl_ctn = $lbl_ctn

var demanda: Array = []
var padroes_corte_salvos_valor: Array = []
var vbox_padroes_lista: Container 

const custom_ms = Vector2(70, 70)

func _ready():
	tooltip_armas.visible = false
	vbox_container.mouse_entered.connect(_exibir_tooltip_total)
	vbox_container.mouse_exited.connect(_esconder_tooltip)

func _process(_delta):
	if tooltip_armas.visible:
		tooltip_armas.global_position = get_global_mouse_position() + Vector2(15, 15)

func _exibir_tooltip_total():
	if not Global.contrato_ativo: return
	
	var linhas: Array = []
	for i in demanda.size():
		if demanda[i] > 0:
			linhas.append("%d %s" % [demanda[i], Global.pecas_disponiveis[i].nome])
			
	if linhas.is_empty(): return
	label_tooltip.text = "\n".join(linhas)
	tooltip_armas.visible = true

func _esconder_tooltip():
	tooltip_armas.visible = false

func inicializar(p_demanda: Array, p_vbox: Container, p_padroes_valores: Array) -> void:
	demanda = p_demanda
	vbox_padroes_lista = p_vbox
	padroes_corte_salvos_valor = p_padroes_valores

func atualizar():
	lbl_ctn.visible = (Global.contrato_ativo == null)
	if not Global.contrato_ativo:
		_esconder_tooltip()
		
	_gerar_visualizacao_demanda()
	_atualizar_pintura_demanda()

func _gerar_visualizacao_demanda():
	for c in container_chapa.get_children():
		c.queue_free()

	if not Global.contrato_ativo: return

	# Metas
	for i in demanda.size():
		if demanda[i] <= 0: continue
		var peca = Global.pecas_disponiveis[i]
		
		var linha = HBoxContainer.new()
		linha.name = "LinhaMeta_" + str(i)
		linha.set_meta("tipo_id", i)
		linha.set_meta("qtd_necessaria", demanda[i])
		
		var icone = Global._criar_icone_arma(peca, i)
		icone.custom_minimum_size = custom_ms
		
		var label = Label.new()
		label.name = "TextoProgresso"
		label.text = "0/%d" % demanda[i]
		
		linha.add_child(icone)
		linha.add_child(label)
		linha.modulate = Color(0.8, 0.8, 0.8)
		container_chapa.add_child(linha)
			
	var quebra = Control.new()
	quebra.custom_minimum_size = Vector2(2000, 0) 
	container_chapa.add_child(quebra)

	# Desperdícios
	for i in demanda.size():
		var peca = Global.pecas_disponiveis[i]
		var linha = HBoxContainer.new()
		linha.name = "LinhaDesperdicio_" + str(i)
		linha.set_meta("tipo_id", i)
		linha.visible = false

		var label = Label.new()
		label.name = "TextoPerda"
		label.text = " x0"
		
		var icone = Global._criar_icone_arma(peca, i)
		icone.custom_minimum_size = custom_ms
		
		linha.add_child(icone)
		linha.add_child(label)
		linha.modulate = Color(0.9, 0.2, 0.2)
		container_chapa.add_child(linha)

func _atualizar_pintura_demanda():
	var producao_total = [0, 0, 0, 0, 0, 0] 
	
	if vbox_padroes_lista and not padroes_corte_salvos_valor.is_empty():
		for linha in vbox_padroes_lista.get_children():
			if linha.has_meta("composicao"):
				var comp = linha.get_meta("composicao") 
				for i in comp.size():
					producao_total[i] += comp[i] * linha.quantidade
				
	for c in container_excesso.get_children():
		c.queue_free()

	for filho in container_chapa.get_children():
		if not filho.has_meta("tipo_id"): continue
		var tipo_id = filho.get_meta("tipo_id")

		if filho.name.begins_with("LinhaMeta_"):
			var qtd_necessaria = filho.get_meta("qtd_necessaria")
			var qtd_feita = producao_total[tipo_id]
			var qtd_exibida = mini(qtd_feita, qtd_necessaria)
			
			filho.get_node("TextoProgresso").text = " %d/%d" % [qtd_exibida, qtd_necessaria]
			filho.modulate = Color(0.2, 0.8, 0.2) if qtd_feita >= qtd_necessaria else Color(0.8, 0.8, 0.8)
				
		elif filho.name.begins_with("LinhaDesperdicio_"):
			var desperdicio = producao_total[tipo_id] - demanda[tipo_id]
			if desperdicio > 0 and Global.contrato_ativo:
				Global._verificar_gatilho_tutorial("primeiro_desperdicio")
				filho.get_node("TextoPerda").text = " x%d" % desperdicio
				filho.visible = true
			else:
				filho.visible = false
