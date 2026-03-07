#CENA DO CONTRATO
extends Control

@export var cena_botao_ui: PackedScene

@onready var container_contratos = $UI/ScrollContainer/VBoxContratos
@onready var btn = $UI/BtnVoltar
@onready var label_dinheiro = $UI/LabelDinheiro

#variavel inicial, somente para testes
var lista_contratos = []

func _ready():
	lista_contratos = Global.contratos_disponiveis
	
	_atualizar_ui_dinheiro()
	_gerar_lista_contratos()
	_configurar_botoes_navegacao()

func _atualizar_ui_dinheiro():
	if label_dinheiro: label_dinheiro.text = "R$ %d" % Global.dinheiro

func _gerar_lista_contratos():
	for c in container_contratos.get_children(): c.queue_free()
	
	container_contratos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container_contratos.size_flags_vertical = Control.SIZE_EXPAND_FILL

	for contrato in lista_contratos: gerar_contrato(contrato)

func _configurar_botoes_navegacao():
	
	btn.text = "Voltar ao Menu" 
	btn.pressed.connect(_on_voltar_pressed)

		
##Gera um contrato para a página de contratos
func gerar_contrato(contrato):
	var card = PanelContainer.new(); card.custom_minimum_size = Vector2(320, 150); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new(); vbox.alignment = BoxContainer.ALIGNMENT_CENTER; vbox.add_theme_constant_override("separation", 10)
	var margin = MarginContainer.new(); margin.add_theme_constant_override("margin_left", 10); margin.add_theme_constant_override("margin_right", 10)
	
	card.add_child(margin); margin.add_child(vbox)
	
	#Nome do Contrato
	var lbl_nome = Label.new(); lbl_nome.text = "📜 " + contrato.nome
	lbl_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lbl_nome.add_theme_font_size_override("font_size", 22)
	vbox.add_child(lbl_nome)
	
	#Detalhes da Demanda
	var lbl_dem = Label.new(); var list_txt = []
	for i in contrato.demanda.size():
		if contrato.demanda[i] > 0:
			list_txt.append("%dx %s" % [contrato.demanda[i], Global.pecas_disponiveis[i].nome])
	
	lbl_dem.text = "Pedido: " + ", ".join(list_txt)
	lbl_dem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lbl_dem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_dem.add_theme_font_size_override("font_size", 14); vbox.add_child(lbl_dem)
	
	#Valor da Recompensa
	var lbl_val = Label.new(); lbl_val.text = "Pagamento: R$ %d" % contrato.recompensa
	lbl_val.modulate = Color.SPRING_GREEN; lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_val.add_theme_font_size_override("font_size", 16); vbox.add_child(lbl_val)
	
	#Botão de aceitar o contrato
	if cena_botao_ui:
		var btn = cena_botao_ui.instantiate(); btn.custom_minimum_size = Vector2(0, 45)
		if Global.contrato_ativo != null:
			btn.disabled = true; btn.text = "Trabalho em Andamento..."
		elif Global.contratos_concluidos.has(contrato):
			btn.disabled = true; btn.text = "Contrato Concluído!"
		else:
			btn.text = "Aceitar Contrato"; btn.pressed.connect(func(): _aceitar_contrato(contrato))
		vbox.add_child(btn)
	container_contratos.add_child(card)	

func _aceitar_contrato(contrato_escolhido):
	var popup = Global.PREFAB_POPUP.instantiate()
	add_child(popup)
	popup.mostrar_mensagem("Contrato aceito!")
	Global.contrato_ativo = contrato_escolhido
	

func _on_voltar_pressed():
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
