extends Node2D

@onready var container_chapa = $VBoxContainer/ContainerChapa
@onready var container_excesso = $VBoxContainer/ContainerExcesso

var demanda: Array = []
var padroes_corte_salvos_valor: Array = []
var vbox_padroes_lista: Container 

func inicializar(p_demanda: Array, p_vbox: Container, p_padroes_valores: Array) -> void:
	demanda = p_demanda
	vbox_padroes_lista = p_vbox
	padroes_corte_salvos_valor = p_padroes_valores
	
	_gerar_visualizacao_demanda()
	_atualizar_pintura_demanda()

func _gerar_visualizacao_demanda():
	if Global.contrato_ativo == null: return
	for i in demanda.size():
		var qtd_necessaria = demanda[i]
		if qtd_necessaria > 0:
			var peca_info = Global.pecas_disponiveis[i]
			
			var linha_meta = HBoxContainer.new()
			linha_meta.name = "LinhaMeta_" + str(i)
			linha_meta.set_meta("tipo_id", i)
			linha_meta.set_meta("qtd_necessaria", qtd_necessaria)
			
			var icone = Global._criar_icone_arma(peca_info, i)
			
			var label_progresso = Label.new()
			label_progresso.name = "TextoProgresso"
			label_progresso.text = "0/%d" % qtd_necessaria
			
			linha_meta.add_child(icone)
			linha_meta.add_child(label_progresso)
			linha_meta.modulate = Color(0.8, 0.8, 0.8, 1.0)
			
			container_chapa.add_child(linha_meta)
			
	var quebra_linha = Control.new()
	quebra_linha.custom_minimum_size = Vector2(2000, 0) 
	container_chapa.add_child(quebra_linha)

	for i in demanda.size():
		var peca_info = Global.pecas_disponiveis[i]
		var linha_desperdicio = HBoxContainer.new()
		linha_desperdicio.name = "LinhaDesperdicio_" + str(i)
		linha_desperdicio.set_meta("tipo_id", i)
		linha_desperdicio.visible = false

		var label_perda = Label.new()
		label_perda.name = "TextoPerda"
		label_perda.text = " x0"
		
		linha_desperdicio.add_child(Global._criar_icone_arma(peca_info, i))
		linha_desperdicio.add_child(label_perda)
		linha_desperdicio.modulate = Color(0.9, 0.2, 0.2, 1.0)
		
		container_chapa.add_child(linha_desperdicio)

func _atualizar_pintura_demanda():
	var producao_total = [0, 0, 0, 0, 0, 0] 
	
	if vbox_padroes_lista != null and not padroes_corte_salvos_valor.is_empty():
		for linha in vbox_padroes_lista.get_children():
			var qtd_uso = linha.quantidade 
			if linha.has_meta("composicao"):
				var composicao = linha.get_meta("composicao") 
				for i in composicao.size():
					producao_total[i] += (composicao[i] * qtd_uso)
				
	for c in container_excesso.get_children(): c.queue_free()
	for filho in container_chapa.get_children():
		if College_name_check(filho.name, "LinhaMeta_") and filho.has_meta("tipo_id"):
			var qtd_necessaria = filho.get_meta("qtd_necessaria")
			var qtd_feita = producao_total[filho.get_meta("tipo_id")]
			var qtd_exibida = qtd_feita if qtd_feita <= qtd_necessaria else qtd_necessaria
			
			filho.get_node_or_null("TextoProgresso").text = " %d/%d" % [qtd_exibida, qtd_necessaria]
			filho.modulate = Color(0.2, 0.8, 0.2, 1.0) if qtd_feita >= qtd_necessaria else Color(0.8, 0.8, 0.8, 1.0)
				
		elif College_name_check(filho.name, "LinhaDesperdicio_") and filho.has_meta("tipo_id"):
			var qtd_desperdicio = producao_total[filho.get_meta("tipo_id")] - demanda[filho.get_meta("tipo_id")]
			
			if qtd_desperdicio > 0:
				Global._verificar_gatilho_tutorial("primeiro_desperdicio")
				filho.get_node_or_null("TextoPerda").text = " x%d" % qtd_desperdicio
				filho.visible = true
			else:
				filho.visible = false

func College_name_check(n: String, prefix: String) -> bool:
	return n.begins_with(prefix)
