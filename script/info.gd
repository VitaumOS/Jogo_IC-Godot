extends HBoxContainer

func _ready() -> void:
	$DiaPanel.text = "DIA: %d" % Global.dia_atual
	$DinheiroPanel.text = "R$ %d" % Global.dinheiro
	$LabelQuantidade.text = "Chapas: %d" % Global.estoque_chapas

func atualizar():
	$DinheiroPanel.text = "R$ %d" % Global.dinheiro
	$LabelQuantidade.text = "Chapas: %d" % Global.estoque_chapas
