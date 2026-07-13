extends Control

var cena_padrao_visual = load("res://scene/aux_scene/Padrao_Corte.tscn")
var restricao = load("res://scene/aux_scene/restricao.tscn")
var miniatura = load("res://scene/aux_scene/miniatura_modelo_chapa.tscn")
var termo_restricao = load("res://scene/aux_scene/termo_restricao.tscn")


@onready var funcao_objetivo_lbl = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelFuncao/FuncaoObjetivo
@onready var container_funcao = $MainMargin/LayoutPrincipal/PainelEsquerdo/PainelFuncao
@onready var container_restricoes = $MainMargin/LayoutPrincipal/PainelEsquerdo/ScrollRestricoes/ContainerRestricoes
@onready var container_padroes_selecao = $MainMargin/LayoutPrincipal/PainelDireito/ScrollPadroes/ContainerPadroesSelecao
@onready var resultado_lbl = $ResultadoCortesLabel 
@onready var btn_voltar = $MainMargin/LayoutPrincipal/Botoes/Voltar

var lista_problemas: Array = []
var indice_problema_atual: int = 0
var problema_atual: Dictionary

var inputs_quantidade_padrao: Dictionary = {} 
var lista_demandas_meta: Array = [] 

func _ready() -> void:
	_carregar_todos_os_desafios()
	_inicializar_problema(indice_problema_atual)
	btn_voltar.visible=false
	
	Global._verificar_gatilho_tutorial("treinamento_modelagem")

func _carregar_todos_os_desafios():
	var arquivo = FileAccess.open("res://data_json/desafios_pcu.json", FileAccess.READ)
	var conteudo = arquivo.get_as_text()
	arquivo.close()
	
	var json = JSON.new()
	if json.parse(conteudo) == OK:
		lista_problemas = json.data.get("problemas", [])

func _inicializar_problema(indice: int):
	if indice >= lista_problemas.size():
		_finalizar_treino()
		return
		
	problema_atual = lista_problemas[indice]
	inputs_quantidade_padrao.clear()
	
	if resultado_lbl:
		resultado_lbl.text = ""
		resultado_lbl.modulate = Color.WHITE
	
	_gerar_lista_direita_padroes_treino()
	_gerar_restricoes_demanda_treino()
	_atualizar_equacoes_na_tela()

func _gerar_lista_direita_padroes_treino() -> void:
	for child in container_padroes_selecao.get_children():
		child.queue_free()
		
	var i = 0
	for padrao in problema_atual.padroes_disponiveis:
		var h_box_item = HBoxContainer.new()
		h_box_item.custom_minimum_size = Vector2(0, 60)
		
		var input_qtd = LineEdit.new()
		input_qtd.custom_minimum_size = Vector2(70, 0)
		input_qtd.alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_qtd.placeholder_text = "Vezes"
		input_qtd.text = "0" 
		
		h_box_item.add_child(input_qtd)
		inputs_quantidade_padrao[i] = input_qtd
		
		var instancia_visual = cena_padrao_visual.instantiate()
		h_box_item.add_child(instancia_visual)
			
		var visualizador = instancia_visual.find_child("Visualizador_Padrao")
		_desenhar_sprites_no_visualizador(visualizador, padrao.get("composicao", []))
		
		container_padroes_selecao.add_child(h_box_item)
		i += 1

func _desenhar_sprites_no_visualizador(container: HBoxContainer, composicao: Array) -> void:
	for i in range(composicao.size()):
		var qtd = composicao[i]
		var peca = Global.pecas_disponiveis[i]
		for n in range(qtd):
			var wrapper = Control.new(); wrapper.custom_minimum_size = Vector2(peca.largura, 50)
			var s = Sprite2D.new(); s.texture = load(peca.caminho_textura)
			if s.texture:
				var t_size = s.texture.get_size()
				s.scale = Vector2(peca.largura / t_size.x, 50.0 / t_size.y)
				s.position = Vector2(peca.largura / 2.0, 25)
			wrapper.add_child(s)
			container.add_child(wrapper)

func _gerar_restricoes_demanda_treino() -> void:
	for child in container_restricoes.get_children():
		child.queue_free()
		
	var demanda_desafio = problema_atual.demanda
	for i in range(demanda_desafio.size()):
		if demanda_desafio[i] > 0:
			var rest = restricao.instantiate()
			rest.find_child("Peca").texture = load(Global.pecas_disponiveis[i].caminho_textura)
			var lbl_tecnica = rest.find_child("Restricao")

			for child in lbl_tecnica.get_children():
				child.queue_free()
				
			var primeiro_termo = true
			for j in range(problema_atual.padroes_disponiveis.size()):
				var padrao = problema_atual.padroes_disponiveis[j]
				var comp_padrao = padrao.get("composicao", [])
				var qtd_na_chapa = comp_padrao[i] if i < comp_padrao.size() else 0
				
				if qtd_na_chapa > 0:
					if not primeiro_termo:
						var lbl_mais = Label.new()
						lbl_mais.text = "          +"
						lbl_mais.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						lbl_tecnica.add_child(lbl_mais)
					primeiro_termo = false
					
					var termo = termo_restricao.instantiate()
					var lbl_qtd = termo.find_child("Qtd")
					lbl_qtd.text = str(qtd_na_chapa)		
					termo.find_child("Miniatura").find_child("Numero").text = str(j + 1)
					lbl_tecnica.add_child(termo)

			if primeiro_termo:
				var lbl_zero = Label.new()
				lbl_zero.text = "0"
				lbl_zero.add_theme_font_size_override("font_size", 26)
				lbl_tecnica.add_child(lbl_zero)
			
			var demanda = rest.find_child("demanda")
			demanda.text = str(demanda_desafio[i])
			
			container_restricoes.add_child(rest)

func _atualizar_equacoes_na_tela() -> void:
	var termos_funcao_obj = []
	for i in range(problema_atual.padroes_disponiveis.size()):
		termos_funcao_obj.append(str(i + 1))
	funcao_objetivo_lbl.text = "Minimizar Z = "
	container_funcao.add_theme_constant_override("separation", 8)
		
	for child in container_funcao.get_children():
		if child != funcao_objetivo_lbl:
			child.queue_free()

	for i in range(problema_atual.padroes_disponiveis.size()):
		if i > 0:
			var lbl_mais = Label.new(); lbl_mais.text = "          +"
			container_funcao.add_child(lbl_mais)
		var mini = miniatura.instantiate()
		container_funcao.add_child(mini)
		mini.find_child("Numero").text = str(i + 1)

func _on_resolver_pressed() -> void:
	var producao_usuario = [0, 0, 0, 0, 0, 0]
	var total_chapas_utilizadas: int = 0
	
	for idx in inputs_quantidade_padrao.keys():
		var input_edit = inputs_quantidade_padrao[idx] as LineEdit
		var vezes_cortar = int(input_edit.text.strip_edges()) if input_edit.text.strip_edges() != "" else 0
		
		total_chapas_utilizadas += vezes_cortar
		
		var padrao = problema_atual.padroes_disponiveis[idx]
		var composicao = padrao.get("composicao", [])
		
		for i in composicao.size():
			producao_usuario[i] += (composicao[i] * vezes_cortar)
			
	var demanda_exigida = problema_atual.demanda
	var atendeu_demanda: bool = true
	
	for i in range(demanda_exigida.size()):
		if producao_usuario[i] < demanda_exigida[i]:
			atendeu_demanda = false
			break
			
	var limite_otimo = problema_atual.get("minimo_chapas_otimo", 999)
			
	if not atendeu_demanda:
		_disparar_dialogo_local([
			{"nome": "Mestre Gato", "texto": "Você chegou perto, mas a quantidade de peças produzidas ainda não atende à restrição de demanda do cliente!"}
		])
	elif total_chapas_utilizadas > limite_otimo:
		_disparar_dialogo_local([
			{"nome": "Mestre Gato", "texto": "Você atendeu à demanda, mas usou [b]%d chapas[/b].A modelagem matemática prova que é possível resolver esse problema usando apenas [b]%d chapas[/b]! Ou seja, você desperdiçou valiosas chapas! Tente otimizar seus cortes." % [total_chapas_utilizadas, limite_otimo]}
		])
	else:
		_disparar_dialogo_local([
			{"nome": "Mestre Gato", "texto": "Perfeito, Jorge! Você encontrou a solução ótima gastando apenas %d chapa(s). Vamos para o próximo!" % total_chapas_utilizadas}
		])
		indice_problema_atual += 1
		_inicializar_problema(indice_problema_atual)

func _disparar_dialogo_local(falas: Array):
	var node_dialogo = get_node_or_null("SistemaDialogo")
	for fala in falas:
		fala["retrato"] = "res://Sprite/gatinhos/Ferreiro.png"
		fala["retrato"] = load(fala["retrato"])
	node_dialogo.iniciar_dialogo(falas)

func _finalizar_treino():
	_disparar_dialogo_local([
		{"nome": "Mestre Gato", "texto": "Incrível, Jorge! Você provou que domina a modelagem e completou todos os exercícios."}
	])
	Global.finalizou_treino=true
	btn_voltar.visible=true
	
func _on_voltar_pressed(): get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
