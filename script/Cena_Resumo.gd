#CENA DE RESUMO DIÁRIO

extends Control

## Cena do botão exportada do Inspector
@export var cena_botao_ui: PackedScene

# Referências aos nós (ajuste os nomes se necessário)
@onready var color_rect = $ColorRect
@onready var center_container = $CenterContainer
@onready var vbox = $CenterContainer/PanelContainer/MarginContainer/VBox
@onready var label_titulo =$CenterContainer/PanelContainer/MarginContainer/VBox/Titulo
@onready var vbox_relatorio = $CenterContainer/PanelContainer/MarginContainer/VBox/VboxTexto

func _ready():
	_configurar_layout_base()
	_processar_financeiro_do_dia()
	_criar_botao_proximo_dia()

## Define todos os tamanhos e alinhamentos via código para evitar erros de UI
func _configurar_layout_base():
	self.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0.8)
	#Centralizar o painel de resumo
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#Configurar espaçamentos do VBox
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 15)
	
	#Configurar texto do Label
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 25)

## Calcula os valores finais e exibe na tela
func _processar_financeiro_do_dia():
	var ganhos = Global.ganhos_do_dia
	var custos = Global.CUSTO_DIARIO
	var lucro_liquido = ganhos - custos
	
	# Atualiza o saldo real no Global
	Global.dinheiro -= custos
	label_titulo.text = "\nRELATÓRIO DO DIA %d " % Global.dia_atual
	
	var label_info: Label = Label.new()
	label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_info.add_theme_font_size_override("font_size", 18)
	label_info.text = ""
	label_info.text += "Faturamento: R$ %d\n" % ganhos
	label_info.text += "Custos Fixos: - R$ %d\n" % custos
	
	var label_info1: Label = Label.new()
	label_info1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_info1.add_theme_font_size_override("font_size", 18)
	if lucro_liquido > 0:
		label_info1.text = "Lucro Líquido: R$%d\n" % lucro_liquido
		label_info1.modulate = Color.GREEN
	else:
		label_info1.text = "Prejuízo: R$ %d\n" % lucro_liquido
		label_info1.modulate = Color.RED
	
	var label_info2: Label = Label.new()
	label_info2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_info2.add_theme_font_size_override("font_size", 18)	
	label_info2.text = "SALDO TOTAL: R$ %d" % Global.dinheiro
	
	vbox_relatorio.add_child(label_info)
	vbox_relatorio.add_child(label_info1)
	vbox_relatorio.add_child(label_info2)

## Instancia o botão para avançar
func _criar_botao_proximo_dia():
	var btn = cena_botao_ui.instantiate()
	btn.text = "Encerrar Dia e Dormir"
	btn.custom_minimum_size = Vector2(0, 50)
	
	# Conecta o clique ao Global para resetar o dia
	btn.pressed.connect(func():Global.proximo_dia())
	vbox.add_child(btn)
