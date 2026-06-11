extends Control

# --- CAMINHO FIXO DA CENA DO PADRÃO ---
var cena_padrao_visual = load("res://scene/Padrao_Corte.tscn")

# --- REFERÊNCIAS DOS NÓS (USANDO IDENTIFICAÇÃO DA SUA IMAGEM) ---
@onready var funcao_objetivo_lbl = $MainMargin/LayoutPrincipal/PainelEsquerdo/FuncaoObjetivo
@onready var container_restricoes = $MainMargin/LayoutPrincipal/PainelEsquerdo/ScrollRestricoes/ContainerRestricoes
@onready var container_padroes_selecao = $MainMargin/LayoutPrincipal/PainelDireito/ScrollPadroes/ContainerPadroesSelecao
@onready var resultado_lbl = $ResultadoCortesLabel # Garanta que esse nó existe na cena se for exibir textos de erro/sucesso nele

# --- CONTROLE INTERNO DOS DESAFIOS ---
var lista_problemas: Array = []
var indice_problema_atual: int = 0
var problema_atual: Dictionary

var inputs_quantidade_padrao: Dictionary = {} # Guarda as caixas de texto de vezes a cortar [idx -> LineEdit]
var lista_demandas_meta: Array = [] # Guarda os valores puros das metas do problema atual

func _ready() -> void:
	_carregar_todos_os_desafios()
	_inicializar_problema(indice_problema_atual)

# --- CARREGA O ARQUIVO JSON DE DESAFIOS ---
func _carregar_todos_os_desafios():
	if not FileAccess.file_exists("res://data_json/desafios_pcu.json"):
		print("ERRO: Arquivo de desafios não encontrado!")
		return
		
	var arquivo = FileAccess.open("res://data_json/desafios_pcu.json", FileAccess.READ)
	var conteudo = arquivo.get_as_text()
	arquivo.close()
	
	var json = JSON.new()
	if json.parse(conteudo) == OK:
		lista_problemas = json.data.get("problemas", [])

# --- INICIALIZA O DESAFIO ATUAL ---
func _inicializar_problema(indice: int):
	if indice >= lista_problemas.size():
		_finalizar_treino()
		return
		
	problema_atual = lista_problemas[indice]
	inputs_quantidade_padrao.clear()
	
	# Restaura o feedback de texto se houver a label
	if resultado_lbl:
		resultado_lbl.text = ""
		resultado_lbl.modulate = Color.WHITE
	
	# 1. Monta o Painel Direito com os Padrões Propostos (Todos já incluídos por padrão)
	_gerar_lista_direita_padroes_treino()
	
	# 2. Monta o Painel Esquerdo com as Restrições Matemáticas rígidas do JSON
	_gerar_restricoes_demanda_treino()
	
	# 3. Renderiza a formulação inicial x1, x2... na tela
	_atualizar_equacoes_na_tela()

# --- PAINEL DIREITO: INSTANCIA OS PADRÕES E CRIA O INPUT NUMÉRICO ---
func _gerar_lista_direita_padroes_treino() -> void:
	for child in container_padroes_selecao.get_children():
		child.queue_free()
		
	var i = 0
	for padrao in problema_atual.padroes_disponiveis:
		var h_box_item = HBoxContainer.new()
		h_box_item.custom_minimum_size = Vector2(0, 60)
		
		# Criamos um LineEdit no lugar do botão Toggle para coletar a resposta do usuário
		var input_qtd = LineEdit.new()
		input_qtd.custom_minimum_size = Vector2(70, 0)
		input_qtd.alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_qtd.placeholder_text = "Vezes"
		input_qtd.text = "0" # Começa zerado
		
		# Filtro Regex para aceitar apenas inteiros positivos
		input_qtd.text_changed.connect(func(novo_texto):
			input_qtd.text = RegEx.create_from_string("[0-9]*").search(novo_texto).get_string()
			_atualizar_equacoes_na_tela() # Atualiza os calculos em tempo real se quiser monitorar
		)
		
		h_box_item.add_child(input_qtd)
		inputs_quantidade_padrao[i] = input_qtd
		
		# Instancia a arte visual das armas dentro da chapa (Igual ao seu sistema)
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

# --- PAINEL ESQUERDO: GERA AS EQUAÇÕES BASEADAS NO DESAFIO DO JSON ---
func _gerar_restricoes_demanda_treino() -> void:
	if not container_restricoes: return
	
	for child in container_restricoes.get_children():
		child.queue_free()
		
	var demanda_desafio = problema_atual.demanda
	for i in range(demanda_desafio.size()):
		if demanda_desafio[i] > 0:
			var nome_peca = Global.pecas_disponiveis[i].nome
			
			var h_box = HBoxContainer.new()
			h_box.alignment = BoxContainer.ALIGNMENT_CENTER
			
			var lbl_nome = Label.new()
			lbl_nome.text = nome_peca + ": "
			h_box.add_child(lbl_nome)
			
			var lbl_tecnica = Label.new()
			lbl_tecnica.name = "CoeficientesPeca_" + str(i)
			lbl_tecnica.text = "0"
			h_box.add_child(lbl_tecnica)
			
			var lbl_sinal = Label.new()
			lbl_sinal.text = "  >=  "
			h_box.add_child(lbl_sinal)
			
			# Aqui a meta é fixa (Vem do JSON), o jogador não edita ela, ele edita o corte na direita!
			var lbl_meta_fixa = Label.new()
			lbl_meta_fixa.text = str(demanda_desafio[i])
			lbl_meta_fixa.modulate = Color(1.0, 0.8, 0.3) # Cor dourada/destacada para a meta
			
			h_box.add_child(lbl_meta_fixa)
			container_restricoes.add_child(h_box)

func _atualizar_equacoes_na_tela() -> void:
	var termos_funcao_obj = []
	
	# Como todos os padrões estão inclusos no problema, varre a lista completa deles
	for i in range(problema_atual.padroes_disponiveis.size()):
		termos_funcao_obj.append("x" + str(i + 1))
		
	funcao_objetivo_lbl.text = "Função Objetivo (Minimizar Chapas):\nMin Z = " + " + ".join(termos_funcao_obj)
		
	var demanda_desafio = problema_atual.demanda
	for i in range(demanda_desafio.size()):
		if demanda_desafio[i] > 0:
			var lbl_coef = container_restricoes.find_child("CoeficientesPeca_" + str(i), true, false) as Label
			if lbl_coef:
				var termos_da_peca = []
				
				for j in range(problema_atual.padroes_disponiveis.size()):
					var padrao = problema_atual.padroes_disponiveis[j]
					var comp_padrao = padrao.get("composicao", [])
					var qtd_na_chapa = comp_padrao[i] if i < comp_padrao.size() else 0
					
					if qtd_na_chapa > 0:
						termos_da_peca.append(str(qtd_na_chapa) + "x" + str(j + 1))
						
				if termos_da_peca.is_empty():
					lbl_coef.text = "0"
				else:
					lbl_coef.text = " + ".join(termos_da_peca)

# --- BOTÃO CONECTADO AO SINAL 'PRESSED' DO SEU NÓ "Resolver" ---
func _on_resolver_pressed() -> void:
	var producao_usuario = [0, 0, 0, 0, 0, 0]
	var total_chapas_utilizadas: int = 0
	
	# 1. Captura as escolhas do jogador e calcula o total de chapas gastas (Z)
	for idx in inputs_quantidade_padrao.keys():
		var input_edit = inputs_quantidade_padrao[idx] as LineEdit
		var vezes_cortar = int(input_edit.text.strip_edges()) if input_edit.text.strip_edges() != "" else 0
		
		total_chapas_utilizadas += vezes_cortar
		
		var padrao = problema_atual.padroes_disponiveis[idx]
		var composicao = padrao.get("composicao", [])
		
		for i in composicao.size():
			producao_usuario[i] += (composicao[i] * vezes_cortar)
			
	# 2. Valida se a produção atende à demanda
	var demanda_exigida = problema_atual.demanda
	var atendeu_demanda: bool = true
	
	for i in range(demanda_exigida.size()):
		if producao_usuario[i] < demanda_exigida[i]:
			atendeu_demanda = false
			break
			
	# 3. Recupera o limite ótimo do JSON
	var limite_otimo = problema_atual.get("minimo_chapas_otimo", 999)
			
	# 4. Controle de feedbacks e condições de vitória
	if not atendeu_demanda:
		_disparar_dialogo_local([
			{"nome": "Mestre Gato", "texto": "Você chegou perto, mas a quantidade de peças produzidas ainda não atende à restrição de demanda do cliente!"}
		])
	elif total_chapas_utilizadas > limite_otimo:
		_disparar_dialogo_local([
			{"nome": "Mestre Gato", "texto": "Você atendeu à demanda, mas usou [b]%d chapas[/b]. A modelagem matemática prova que é possível resolver esse problema usando apenas [b]%d chapas[/b]! Tente otimizar seus cortes." % [total_chapas_utilizadas, limite_otimo]}
		])
	else:
		# Se atendeu à demanda e usou o número ótimo de chapas (ou menos)
		_disparar_dialogo_local([
			{"nome": "Mestre Gato", "texto": "Perfeito, Jorge! Você encontrou a solução ótima gastando apenas %d chapa(s). Vamos para o próximo!" % total_chapas_utilizadas}
		])
		indice_problema_atual += 1
		_inicializar_problema(indice_problema_atual)

# --- BOTÃO CONECTADO AO SINAL 'PRESSED' DO SEU NÓ "Voltar" ---
func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/MenuInicial.tscn")

func _disparar_dialogo_local(falas: Array):
	var node_dialogo = get_node_or_null("SistemaDialogo")
	if node_dialogo and node_dialogo.has_method("iniciar_dialogo"):
		for fala in falas:
			fala["retrato"] = "res://Sprite/gatinhos/NekoJorge.png"
			fala["retrato"] = load(fala["retrato"])
		node_dialogo.iniciar_dialogo(falas)

func _finalizar_treino():
	_disparar_dialogo_local([
		{"nome": "Mestre Gato", "texto": "Incrível, Jorge! Você provou que domina a modelagem e completou todos os exercícios. Retornando ao menu principal..."}
	])
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scene/MenuInicial.tscn")
