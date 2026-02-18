extends Node

#Variaveis
var tamanho_container: float = 500.0
var dia_atual: int = 1
var dinheiro: int = 1000
var ganhos_do_dia: int = 0
var tempo_restante: float = 120.0
const DURACAO_DIA = 120.0
const CUSTO_DIARIO = 200 #Aluguel/Impostos

var armas_na_esteira_atual: Array = []
var chapas_usadas_pelo_jogador: int = 0
var ultimo_desempenho_ritmo: float = -1.0 # -1 indica que não veio da forja

var pecas_disponiveis: Array = [
	{"nome": "Adaga", "largura": 50.0, "caminho_textura": "res://Sprite/adaga.png"},
	{"nome": "Espada M", "largura": 95.0, "caminho_textura": "res://Sprite/Esp_Larg.png"},
	{"nome": "Espada G", "largura": 130.0, "caminho_textura": "res://Sprite/Esp_Grande.png"},
	{"nome": "Machado", "largura": 90.0, "caminho_textura": "res://Sprite/machado.png"},
	{"nome": "Arco", "largura": 160.0, "caminho_textura": "res://Sprite/arco.png"},
	{"nome": "Lança", "largura": 220.0, "caminho_textura": "res://Sprite/lanca.png"}
]

#Listas Dinâmicas
var contratos_disponiveis: Array = []
var padroes_na_loja: Array = []

#Inventário Permanente
var contrato_ativo = null
var padroes_desbloqueados: Array = []

func _ready():
	gerar_conteudo_do_dia()

## Gera novos contratos e padrões aleatórios
func gerar_conteudo_do_dia():
	contratos_disponiveis.clear()
	padroes_na_loja.clear()
	
	var dados_contratos = _carregar_json("res://data_json/contratos.json")
	var dados_padroes = _carregar_json("res://data_json/padroes.json")

	var contratos_possiveis = dados_contratos.get("contratos", []).filter(func(c): return c.dia_minimo <= dia_atual)
	var padroes_possiveis = dados_padroes.get("padroes", []).filter(func(p): return p.dia_minimo <= dia_atual)
	
	contratos_possiveis.shuffle()
	for i in range(min(3, contratos_possiveis.size())):
		contratos_disponiveis.append(contratos_possiveis[i])
		
	padroes_possiveis.shuffle()
	for i in range(min(3, padroes_possiveis.size())):
		padroes_na_loja.append(padroes_possiveis[i])

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
func completar_contrato(conseguiu_minimo: bool):
	
	if contrato_ativo != null:
		var recompensa = contrato_ativo.recompensa
		if conseguiu_minimo:
			recompensa*=1.2
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
	dinheiro -= CUSTO_DIARIO
	ganhos_do_dia = 0
	tempo_restante = DURACAO_DIA
	contrato_ativo = null
	gerar_conteudo_do_dia()
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
