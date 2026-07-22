extends Control

@export var card_contrato: PackedScene

@onready var container_contratos = $UI/ScrollContainer/VBoxContratos
@onready var popup = $PopUp

var lista_contratos = []

func _ready():
	lista_contratos = Global.contratos_disponiveis
	_gerar_lista_contratos()
	Global._verificar_gatilho_tutorial("primeiro_mural")


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

##mostra um popup confirmando o contrato e o adiciona no ciclo do jogo
func _aceitar_contrato(contrato_escolhido):
	popup.mostrar_confirmacao("Deseja escolher esse contrato?")
	var confirma = await popup.resposta 
	if confirma:
		Global.contrato_ativo = contrato_escolhido
		_gerar_lista_contratos()
		popup.mostrar_mensagem("Contrato Escolhido!")
