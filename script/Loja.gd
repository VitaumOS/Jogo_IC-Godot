extends Control

const PRECO_PADRAO = 150

## Cena do botão customizado vinda do Inspector
@export var cena_botao_ui: PackedScene

@onready var label_dinheiro = $UI/HBoxContainer/LabelDinheiro
@onready var container_itens = $UI/ScrollContainer/VBoxItens
@onready var btn_voltar: Button= $UI/BtnVoltar
@onready var label_feedback = $UI/LabelFeedback
@onready var lbl_estoque_chapas = $UI/HBoxContainer/LabelQuantidade
@onready var btn_comprar_chapa = $UI/PainelChapas/BtnComprarChapa 

## Lista de padrões inicialmente disponíveis
var catalogo_loja = []

func _ready():
	catalogo_loja = Global.padroes_na_loja
	_gerar_itens_loja()
	btn_voltar.pressed.connect(_on_voltar_pcu)
	_configurar_compra_chapa()
	_atualizar_display()
	
func _configurar_compra_chapa():
	btn_comprar_chapa.text = "Comprar Chapa Extra (R$ %d)" % Global.preco_chapa_extra
	if not btn_comprar_chapa.pressed.is_connected(_comprar_chapa_extra):
		btn_comprar_chapa.pressed.connect(_comprar_chapa_extra)

func _comprar_chapa_extra():
	if Global.dinheiro >= Global.preco_chapa_extra:
		Global.dinheiro -= Global.preco_chapa_extra
		Global.estoque_chapas_extras += 1
		_atualizar_display()
		label_feedback.text = "Chapa extra adquirida!"
	else:
		label_feedback.text = "Saldo insuficiente para chapa!"

func _atualizar_display():
	lbl_estoque_chapas.text = "📦 Chapas: %d" % Global.estoque_chapas_extras
	label_dinheiro.text = "Carteira: R$ %d" % Global.dinheiro
	

## Retorna para a cena principal
func _on_voltar_pcu():
	if get_tree().change_scene_to_file("res://scene/Cena_1.tscn") != OK: print("Erro ao carregar cena")


func _gerar_itens_loja():
	for c in container_itens.get_children(): c.queue_free()
		
	for item in Global.padroes_na_loja:
		var card = PanelContainer.new(); card.custom_minimum_size.y = 100
		var h_box = HBoxContainer.new(); card.add_child(h_box)
		#Visualizador do padrão
		var vis = Control.new() 
		vis.custom_minimum_size = Vector2(500, 60) 
		vis.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var bg = ColorRect.new() 
		bg.color = Color(1, 1, 1, 0.1) 
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		var p_hbox = HBoxContainer.new() 
		p_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) 
		p_hbox.add_theme_constant_override("separation", 2)
		
		vis.add_child(bg); vis.add_child(p_hbox); 
		
		_renderizar_previa_no_card(p_hbox, item.composicao); 
		h_box.add_child(vis)
		
		#Informações e Botão
		var v_info = VBoxContainer.new(); v_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v_info.alignment = BoxContainer.ALIGNMENT_CENTER
		var lbl = Label.new(); lbl.text = item.nome; lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var btn = cena_botao_ui.instantiate(); btn.text = "Comprar (R$ %d)" % item.preco
		
		if _ja_possui(item): btn.disabled = true; btn.text = "Adquirido"
		btn.pressed.connect(func(): _tentar_comprar(item, btn))
		v_info.add_child(lbl); v_info.add_child(btn); h_box.add_child(v_info); container_itens.add_child(card)

## Desenha as miniaturas das peças dentro do card da loja
func _renderizar_previa_no_card(container: HBoxContainer, comp: Array):
	for i in comp.size():
		var peca = Global.pecas_disponiveis[i]
		for n in comp[i]:
			var w = Control.new(); w.custom_minimum_size = Vector2(peca.largura, 50)
			var s = Sprite2D.new(); s.texture = load(peca.caminho_textura)
			if s.texture:
				var t_size = s.texture.get_size()
				s.scale = Vector2(peca.largura / t_size.x, 50.0 / t_size.y)
				s.position = Vector2(peca.largura / 2.0, 30)
			w.add_child(s); container.add_child(w)

func _ja_possui(item) -> bool:
	return Global.padroes_desbloqueados.any(func(p): return p.nome == item.nome)

func _tentar_comprar(item, botao):
	if Global.remover_dinheiro(item.preco):
		Global.padroes_desbloqueados.append(item)
		botao.disabled = true; botao.text = "Adquirido"; _atualizar_display()
		label_feedback.text = "Padrão desbloqueado!"
	else: label_feedback.text = "Saldo insuficiente!"
