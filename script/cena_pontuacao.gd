extends Control

@onready var label1 =$PanelContainer/VBox/VboxTexto/Label1
@onready var label2 =$PanelContainer/VBox/VboxTexto/Label2
@onready var label3 =$PanelContainer/VBox/VboxTexto/Label3
@onready var label4 =$PanelContainer/VBox/VboxTexto/Label4

func _ready() -> void:
	
	label1.text = "Valor do contrato: R$%.2f" % Global.recompensa_base
	var porcentagem_real = Global.ultimo_desempenho_ritmo * 100.0
	label2.text = "Porcentagem de marteladas: %.2f%%" % porcentagem_real
	label4.text = "Total: R$%.2f"% Global.recompensa_final
