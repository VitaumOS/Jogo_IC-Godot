extends HBoxContainer

@onready var contrato = $Contrato
@onready var loja = $Loja
@onready var forja = $Forja
@onready var encerrar = $Encerrar
@onready var popup = $PopUp

func _ready() -> void:
	contrato.disabled = false
	loja.disabled = false
	forja.disabled = false
	
	# Desativa o botão correspondente à cena que está aberta no momento
	if Global.cena_contrato:
		contrato.disabled = true
	elif Global.cena_loja:
		loja.disabled = true
	elif Global.cena_main:
		forja.disabled = true


func organiza_botao(i: int) -> void:
	Global.cena_contrato = (i == 0)
	Global.cena_loja = (i == 1)
	Global.cena_main = (i == 2)

func _on_contrato_pressed() -> void: 
	organiza_botao(0)
	get_tree().change_scene_to_file("res://scene/Cena_contratos.tscn")

func _on_loja_pressed() -> void:
	organiza_botao(1)
	get_tree().change_scene_to_file("res://scene/Cena_Loja.tscn")

func _on_forja_pressed() -> void:
	organiza_botao(2)
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
	
func _on_encerrar_pressed() -> void:
	popup.mostrar_confirmacao("Deseja finalizar o dia?")
	var confirma = await popup.resposta 
	if confirma:
		if !Global.todos_contratos_concluidos():
			popup.mostrar_mensagem("Você precisa concluir todos os contratos do dia!")
			var confirma2 = await popup.resposta 
			if confirma2:
				return
		if Global.dia_atual == 5 and !Global.finalizou_treino:
			popup.mostrar_mensagem("Você precisa concluir o treinamento antes de prosseguir!")
			var confirma2 = await popup.resposta 
			if confirma2:
				return
		organiza_botao(2)
		get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn")
