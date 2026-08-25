extends VBoxContainer

@onready var lbl_qtd = $Control/ControlesQuantidade/HBoxBotoes/lblQtd
@onready var container_visualizador = $EspaçadorVisual/Control/Visualizador_Padrao

var quantidade: int = 0
var dados_do_padrao: Dictionary

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
		sprite.scale = Vector2(p.largura_peca/t_size.x, 50.0/t_size.y)
	
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(p.largura_peca, 20)
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
