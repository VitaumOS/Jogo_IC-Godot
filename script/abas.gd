extends HBoxContainer

@onready var contrato = $Contrato
@onready var loja = $Loja
@onready var forja = $Forja
@onready var encerrar = $Encerrar
@onready var popup = $PopUp

	
func _on_contrato_pressed(): get_tree().change_scene_to_file("res://scene/Cena_contratos.tscn")
func _on_loja_pressed():get_tree().change_scene_to_file("res://scene/Cena_Loja.tscn")
func _on_forja_pressed():get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
func _on_encerrar_pressed():
	popup.mostrar_confirmacao("Deseja finalizar o dia?")
	var confirma = await popup.resposta 
	if confirma:
		get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn")
