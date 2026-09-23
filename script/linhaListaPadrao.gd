extends VBoxContainer

@onready var lbl_qtd = $Control/ControlesQuantidade/HBoxBotoes/lblQtd
@onready var container_visualizador = $EspaçadorVisual/Control/Visualizador_Padrao
@onready var tooltip_armas = $TooltipArmas
@onready var label_tooltip = $TooltipArmas/Label

var quantidade: int = 0
var dados_do_padrao: Dictionary

func _ready():
	tooltip_armas.top_level = true 
	tooltip_armas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_armas.visible = false
	
	mouse_entered.connect(_exibir_tooltip)
	mouse_exited.connect(_esconder_tooltip)

func _process(_delta):
	if tooltip_armas.visible:
		tooltip_armas.global_position = get_global_mouse_position() + Vector2(15, 15)

func _exibir_tooltip():
	var linhas: Array = []
	
	if dados_do_padrao.has("composicao"):
		for i in dados_do_padrao.composicao.size():
			var qtd = dados_do_padrao.composicao[i]
			if qtd > 0:
				linhas.append("%d %s" % [qtd, Global.pecas_disponiveis[i].nome])
	elif dados_do_padrao.has("pecas"):
		var contagem = {}
		for p in dados_do_padrao.pecas:
			var nome = p.get("nome", "Peça")
			contagem[nome] = contagem.get(nome, 0) + 1
		for nome in contagem:
			linhas.append("%d %s" % [contagem[nome], nome])

	if linhas.is_empty(): return
	label_tooltip.text = "\n".join(linhas)
	tooltip_armas.visible = true

func _esconder_tooltip():
	tooltip_armas.visible = false

func configurar(dados: Dictionary):
	self.dados_do_padrao = dados
	for c in container_visualizador.get_children():
		c.queue_free()
	
	var largura_utilizada: float = 0.0
	
	for p in dados.pecas:
		var sprite = Sprite2D.new()
		sprite.texture = load(p.caminho_textura)
		sprite.centered = false
		
		var t_size = sprite.texture.get_size()
		sprite.scale = Vector2(p.largura_peca / t_size.x, 50.0 / t_size.y)
	
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(p.largura_peca, 20)
		wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		wrapper.add_child(sprite)
		container_visualizador.add_child(wrapper)
		
		largura_utilizada += p.largura_peca

func _on_btn_mais_pressed() -> void:
	quantidade += 1
	lbl_qtd.text = str(quantidade)
	
func _on_btn_menos_pressed() -> void:
	if quantidade > 0:
		quantidade -= 1
		lbl_qtd.text = str(quantidade)

func get_quantidade() -> int:
	return quantidade
