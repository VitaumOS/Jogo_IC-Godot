extends HBoxContainer

@onready var contrato = $Contrato
@onready var loja = $Loja
@onready var forja = $Forja
@onready var encerrar = $Encerrar
@onready var popup = $PopUp


func organiza_botao(i):
	Global.cena_contrato = false
	Global.cena_loja = false
	Global.cena_main = false
	
	if i == 0: #contrato
		Global.cena_contrato = true
		contrato.disabled=true
	elif i == 1: #loja
		Global.cena_loja = true
		loja.disabled=true
	elif i == 2: #forja
		Global.cena_main = true
		forja.disabled=true

func _on_contrato_pressed(): 
	organiza_botao(0)
	get_tree().change_scene_to_file("res://scene/Cena_contratos.tscn")
	
func _on_loja_pressed():
	organiza_botao(1)
	get_tree().change_scene_to_file("res://scene/Cena_Loja.tscn")
	
func _on_forja_pressed():
	organiza_botao(2)
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
	
func _on_encerrar_pressed():
	popup.mostrar_confirmacao("Deseja finalizar o dia?")
	var confirma = await popup.resposta 
	if confirma:
		if !Global.fez_contrato_diario:
			popup.mostrar_mensagem("você precisa fazer ao menos um contrato!")
			var confirma2 = await popup.resposta 
			if confirma2:
				return
		organiza_botao(2)
		get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn")
