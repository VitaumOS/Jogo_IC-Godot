extends Control

@export var cena_card: PackedScene

@onready var label_dinheiro = $UI/HBoxContainer/LabelDinheiro
@onready var container_itens = $UI/ScrollContainer/VBoxItens
@onready var label_feedback = $UI/LabelFeedback
@onready var lbl_estoque_chapas = $UI/HBoxContainer/LabelQuantidade
@onready var btn_comprar_chapa = $UI/PainelChapas/BtnComprarChapa 

## Lista de padrões inicialmente disponíveis
var catalogo_loja = []

func _ready():
	catalogo_loja = Global.padroes_na_loja
	btn_comprar_chapa.text = "Comprar Chapas (R$ %d)" % Global.preco_chapa
	_gerar_itens_loja()
	_atualizar_display()
	Global._verificar_gatilho_tutorial("primeira_loja")

func _comprar_chapa():
	if Global.dinheiro >= Global.preco_chapa:
		Global.dinheiro -= Global.preco_chapa
		Global.estoque_chapas += 1
		_atualizar_display()
		label_feedback.text = "Chapa extra adquirida!"
	else:
		label_feedback.text = "Saldo insuficiente para chapa!"

func _atualizar_display():
	lbl_estoque_chapas.text = "Chapas: %d" % Global.estoque_chapas
	label_dinheiro.text = "R$ %d" % Global.dinheiro
	
## Retorna para a cena principal
func _on_voltar_pcu():
	if get_tree().change_scene_to_file("res://scene/Cena_1.tscn") != OK: print("Erro ao carregar cena")

func _gerar_itens_loja():
	for c in container_itens.get_children(): c.queue_free()
	for item in Global.padroes_na_loja:
		var card = cena_card.instantiate()
		container_itens.add_child(card)
		var p_hbox = card.find_child("Control2").find_child("Visualizador_Padrao")
		_renderizar_previa_no_card(p_hbox, item.composicao); 

		card.find_child("NomePadrao").text = item.nome
		var btn = card.find_child("Button"); btn.text = "Comprar (R$ %d)" % item.preco
		if _ja_possui(item): btn.disabled = true; btn.text = "Adquirido"
		btn.pressed.connect(func(): _tentar_comprar(item, btn))

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
				s.position = Vector2(peca.largura / 2.0, 25)
			w.add_child(s); container.add_child(w)

func _ja_possui(item) -> bool:
	return Global.padroes_desbloqueados.any(func(p): return p.nome == item.nome)

func _tentar_comprar(item, botao):
	if Global.remover_dinheiro(item.preco):
		Global.padroes_desbloqueados.append(item)
		botao.disabled = true; botao.text = "Adquirido"; _atualizar_display()
		label_feedback.text = "Padrão desbloqueado!"
	else: label_feedback.text = "Saldo insuficiente!"
