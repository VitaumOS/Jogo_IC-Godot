extends Control

@onready var label_titulo =$CenterContainer/PanelContainer/MarginContainer/VBox/Titulo
@onready var label_info = $CenterContainer/PanelContainer/MarginContainer/VBox/VboxTexto/Label1
@onready var label_info1 = $CenterContainer/PanelContainer/MarginContainer/VBox/VboxTexto/Label2
@onready var label_info2 = $CenterContainer/PanelContainer/MarginContainer/VBox/VboxTexto/Label3

func _ready():
	_processar_financeiro_do_dia()

## Calcula os valores finais e exibe na tela
func _processar_financeiro_do_dia():
	var ganhos = Global.ganhos_do_dia
	var custos = Global.CUSTO_DIARIO
	var lucro_liquido = ganhos - custos
	
	Global.dinheiro -= custos
	label_titulo.text = "\nRELATÓRIO DO DIA %d " % Global.dia_atual
	
	label_info.text = "Faturamento: R$ %d\n" % ganhos
	label_info.text += "Custos Fixos: - R$ %d\n" % custos
	
	if lucro_liquido > 0:
		label_info1.text = "Lucro Líquido: R$%d\n" % lucro_liquido
		label_info1.modulate = Color.GREEN
	else:
		label_info1.text = "Prejuízo: R$ %d\n" % lucro_liquido
		label_info1.modulate = Color.RED
	
	label_info2.text = "SALDO TOTAL: R$ %d" % Global.dinheiro
	
##Ao apertar o botão, começa o próximo dia
func _iniciar_proximo_dia():
	if Global.dinheiro < 0:
		# Se estiver com saldo negativo, vai para a cena de Game Over
		get_tree().change_scene_to_file("res://scene/GameOver.tscn")
	if Global.dia_atual >= Global.DIA_FINAL:
		# Se venceu o último dia, vai para a vitória
		get_tree().change_scene_to_file("res://scene/Vitoria.tscn")
	else:
		Global.proximo_dia()
