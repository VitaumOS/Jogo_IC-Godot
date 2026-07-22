extends Control

@export var cena_card: PackedScene

@onready var container_itens = $UI/ScrollContainer/VBoxItens
@onready var label_feedback = $UI/LabelFeedback
@onready var btn_comprar_chapa = $UI/PainelChapas/BtnComprarChapa 

## Lista de padrões inicialmente disponíveis
var catalogo_loja = []
var padrao_tamanho = 0.0

func _ready():
	catalogo_loja = Global.padroes_na_loja
	btn_comprar_chapa.text = "Comprar Chapas (R$ %d)" % Global.preco_chapa
	_gerar_itens_loja()
	Global._verificar_gatilho_tutorial("primeira_loja")

func _comprar_chapa():
	if Global.dinheiro >= Global.preco_chapa:
		Global.dinheiro -= Global.preco_chapa
		Global.estoque_chapas += 1
		$UI/Info.atualizar()
		label_feedback.text = "Chapa extra adquirida!"
	else:
		label_feedback.text = "Saldo insuficiente para chapa!"

	
func _gerar_itens_loja():
	for c in container_itens.get_children(): c.queue_free()
	for item in Global.padroes_na_loja:
		var card = cena_card.instantiate()
		container_itens.add_child(card)
		var p_hbox = card.find_child("Control2").find_child("Visualizador_Padrao")
		_renderizar_previa_no_card(p_hbox, item.composicao)
		
		var lbl_porc = card.find_child("Control3").find_child("Desperdicio")
		lbl_porc.visible = (!Global.dia_atual == 1)
		var porcentagem = (padrao_tamanho/Global.tamanho_container)*100
		lbl_porc.text = "%.1f%%"%porcentagem
		
		var btn = card.find_child("Button"); btn.text = "R$ %d" % item.preco
		if _ja_possui(item): btn.disabled = true; btn.text = "Adquirido"
		btn.pressed.connect(func(): _tentar_comprar(item, btn))

## Desenha as miniaturas das peças dentro do card da loja
func _renderizar_previa_no_card(container: HBoxContainer, comp: Array):
	padrao_tamanho = 0.0
	for i in comp.size():
		var peca = Global.pecas_disponiveis[i]
		for n in comp[i]:
			var w = Control.new(); w.custom_minimum_size = Vector2(peca.largura, 50)
			var s = Sprite2D.new(); s.texture = load(peca.caminho_textura)
			padrao_tamanho += peca.largura
			var t_size = s.texture.get_size()
			s.scale = Vector2(peca.largura / t_size.x, 50.0 / t_size.y)
			s.position = Vector2(peca.largura / 2.0, 25)
			w.add_child(s); container.add_child(w)

func _ja_possui(item) -> bool:
	return Global.padroes_desbloqueados.any(func(p): return p.nome == item.nome)

func _tentar_comprar(item, botao):
	if Global.remover_dinheiro(item.preco):
		Global.padroes_desbloqueados.append(item)
		botao.disabled = true; botao.text = "Adquirido"; $UI/Info.atualizar()
		label_feedback.text = "Padrão desbloqueado!"
	else: label_feedback.text = "Saldo insuficiente!"
