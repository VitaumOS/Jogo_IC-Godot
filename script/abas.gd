extends HBoxContainer

@onready var contrato = $Contrato
@onready var loja = $Loja
@onready var forja = $Forja
@onready var encerrar = $Encerrar


func _on_contrato_pressed(): get_tree().change_scene_to_file("res://scene/Cena_contratos.tscn")
func _on_loja_pressed():get_tree().change_scene_to_file("res://scene/Cena_Loja.tscn")
func _on_forja_pressed():get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
func _on_encerrar_pressed():get_tree().change_scene_to_file("res://scene/Cena_Resumo.tscn")
