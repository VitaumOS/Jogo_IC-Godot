extends Node

const CUSTO_DIARIO = 200
const DIA_FINAL: int = 7

var tamanho_container: float = 500.0
var dia_atual: int = 1
var dinheiro: int = 10000
var ganhos_do_dia: int = 0
var estoque_chapas: int = 0
var preco_chapa: int = 100 
var recompensa_final: float = 0

var chapas_usadas_pelo_jogador: int = 0
var ultimo_desempenho_ritmo: float = -1.0 

var pecas_disponiveis: Array = [
	{"nome": "Adaga", "largura": 53.0, "caminho_textura": "res://Sprite/adaga.png"},
	{"nome": "Espada M", "largura": 97.0, "caminho_textura": "res://Sprite/Esp_Larg.png"},
	{"nome": "Espada G", "largura": 123.0, "caminho_textura": "res://Sprite/Esp_Grande.png"},
	{"nome": "Machado", "largura": 89.0, "caminho_textura": "res://Sprite/machado.png"},
	{"nome": "Arco", "largura": 167.0, "caminho_textura": "res://Sprite/arco.png"},
	{"nome": "Lança", "largura": 211.0, "caminho_textura": "res://Sprite/lanca.png"}
]

var dialogos_vistos_hoje: Dictionary = {}

var contratos_disponiveis: Array = []
var padroes_na_loja: Array = []
var armas_na_esteira_atual: Array = []
var padroes_desbloqueados: Array = []
var contratos_concluidos: Array = []

var contrato_ativo = null

func _ready():
	gerar_conteudo_do_dia()


# Função adaptada para encontrar e rodar o diálogo na cena atual
func _verificar_gatilho_tutorial(chave_tutorial: String) -> void:
	if not Global.has_meta("tutoriais_vistos"):
		Global.set_meta("tutoriais_vistos", {})
		
	var tutoriais_vistos = Global.get_meta("tutoriais_vistos")
	
	if not tutoriais_vistos.has(chave_tutorial):
		tutoriais_vistos[chave_tutorial] = true 
		Global.set_meta("tutoriais_vistos", tutoriais_vistos)
		
		var todos_dialogos = _carregar_json("res://data_json/dialogos.json")
		
		if todos_dialogos.has(chave_tutorial):
			var falas_do_tutorial = todos_dialogos[chave_tutorial]
			
			if has_node("/root/Dialogo"):
				for fala in falas_do_tutorial:
					if fala.has("retrato") and fala["retrato"] is String:
						fala["retrato"] = load(fala["retrato"])
				Dialogo.iniciar_dialogo(falas_do_tutorial)

func registrar_contrato_concluido(contrato):
	if not contratos_concluidos.has(contrato):
		contratos_concluidos.append(contrato)

func deve_exibir_dialogo_do_dia() -> bool:
	if not dialogos_vistos_hoje.has(dia_atual):
		dialogos_vistos_hoje[dia_atual] = true
		return true
	return false

## Função para consumir a chapa
func usar_chapa_extra():
	if estoque_chapas > 0:
		estoque_chapas -= 1
		return true
	return false
	
## Gera novos contratos e padrões aleatórios
func gerar_conteudo_do_dia():
	contratos_disponiveis.clear()
	
	var dados_contratos = _carregar_json("res://data_json/contratos.json")
	var dados_padroes = _carregar_json("res://data_json/padroes.json")

	var contratos_possiveis = dados_contratos.get("contratos", []).filter(func(c): return c.dia == dia_atual)
	var padroes_possiveis = dados_padroes.get("padroes", []).filter(func(p): return p.dia == dia_atual)
	
	contratos_possiveis.shuffle()
	for i in contratos_possiveis:
		contratos_disponiveis.append(i)
		
	padroes_possiveis.shuffle()
	for i in padroes_possiveis:
		padroes_na_loja.append(i)

## Função auxiliar para ler qualquer arquivo JSON
func _carregar_json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		print("ERRO: Arquivo não encontrado: ", caminho)
		return {}
		
	var arquivo = FileAccess.open(caminho, FileAccess.READ)
	var conteudo = arquivo.get_as_text()
	var json = JSON.new()
	var erro = json.parse(conteudo)
	
	if erro == OK:
		return json.data
	else:
		print("ERRO ao processar JSON: ", json.get_error_message())
		return {}

## Função chamada quando o jogador resolve o PCU com sucesso
func completar_contrato(conseguiu_minimo: bool, ritmo : float):
	if contrato_ativo != null:
		var recompensa = contrato_ativo.recompensa
		var bonus = 0.0
		if conseguiu_minimo:
			bonus = recompensa*0.2
		#a recompensa é dado pela metade da recompensa do contrato + a proporção de acertos + o bonus do mínimo
		recompensa = (recompensa/2.0)+((recompensa*ritmo)/2.0) 
		recompensa += bonus
		recompensa_final = recompensa
		dinheiro += recompensa
		ganhos_do_dia += recompensa
		contrato_ativo = null
		return true
	else:
		return false

func adicionar_dinheiro(qtd: int):
	dinheiro += qtd
	ganhos_do_dia += qtd

func remover_dinheiro(qtd: int) -> bool:
	if dinheiro >= qtd:
		dinheiro -= qtd
		return true
	return false

##Inicia o próximo dia
func proximo_dia():
	dia_atual += 1
	ganhos_do_dia = 0
	contrato_ativo = null
	gerar_conteudo_do_dia()
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
