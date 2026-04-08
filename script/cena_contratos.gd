#CENA DO CONTRATO
extends Control

@export var card_contrato: PackedScene

@onready var container_contratos = $UI/ScrollContainer/VBoxContratos
@onready var label_dinheiro = $UI/LabelDinheiro
@onready var popup = $PopUp

#variavel inicial, somente para testes
var lista_contratos = []

func _ready():
	lista_contratos = Global.contratos_disponiveis
	_atualizar_ui_dinheiro()
	_gerar_lista_contratos()

func _atualizar_ui_dinheiro():
	label_dinheiro.text = "R$ %d" % Global.dinheiro

func _gerar_lista_contratos():
	for c in container_contratos.get_children(): c.queue_free()
	for contrato in lista_contratos: gerar_contrato(contrato)

		
##Gera um contrato para a página de contratos
func gerar_contrato(contrato):
	var card = card_contrato.instantiate()
	
	var lbl_nome = card.find_child("Nome")
	lbl_nome.text = "📜 " + contrato.nome
	
	#Detalhes da Demanda
	var lbl_dem = card.find_child("Demanda"); var list_txt = []
	for i in contrato.demanda.size():
		if contrato.demanda[i] > 0:
			list_txt.append("%dx %s" % [contrato.demanda[i], Global.pecas_disponiveis[i].nome])
	lbl_dem.text = "Pedido: " + ", ".join(list_txt)
	
	#Valor da Recompensa
	var lbl_val = card.find_child("Valor"); lbl_val.text = "Pagamento: R$ %d" % contrato.recompensa
	
	#Botão de aceitar o contrato
	var btn = card.find_child("Btn")
	if Global.contrato_ativo != null:
		btn.disabled = true; btn.text = "Trabalho em Andamento..."
	elif Global.contratos_concluidos.has(contrato):
		btn.disabled = true; btn.text = "Contrato Concluído!"
	else:
		btn.text = "Aceitar Contrato"; btn.pressed.connect(func(): _aceitar_contrato(contrato))

	container_contratos.add_child(card)	

func _aceitar_contrato(contrato_escolhido):
	
	popup.mostrar_confirmacao("Deseja escolher esse contrato?")
	var confirma = await popup.resposta 
	if confirma:
		Global.contrato_ativo = contrato_escolhido
		_on_voltar_pressed()

func _on_voltar_pressed():
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")

func _on_btn_voltar_pressed() -> void:
	_on_voltar_pressed()
