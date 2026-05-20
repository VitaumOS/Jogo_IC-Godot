import pulp
import sys
import json

def resolver_pcu(demanda, padroes, caminho_saida):
    num_tipos = len(demanda)
    num_padroes = len(padroes)

    # Inicializa o modelo de Minimização
    prob = pulp.LpProblem("Minimizar_Chapas", pulp.LpMinimize)
    
    # Variáveis x_j inteiras e não-negativas
    x = [pulp.LpVariable(f"x_{j}", lowBound=0, cat='Integer') for j in range(num_padroes)]
    
    # Função Objetivo: Min Z = x_0 + x_1 + ... + x_n
    prob += pulp.lpSum(x)
    
    # Restrições de Demanda: Somatório de (Padrão * x) >= Demanda
    for i in range(num_tipos):
        prob += pulp.lpSum([x[j] * padroes[j][i] for j in range(num_padroes)]) >= demanda[i]
        
    # Executa o Solver nativo do PuLP sem exibir logs poluindo o console
    status = prob.solve(pulp.PULP_CBC_CMD(msg=0))
    
    status_string = pulp.LpStatus[status]
    
    resultado = {
        "status": status_string,
        "solucao": [int(pulp.value(x[j])) for j in range(num_padroes)] if status_string == "Optimal" else []
    }
    
    # Salva diretamente no caminho exato que o Godot determinou
    with open(caminho_saida, "w") as f:
        json.dump(resultado, f)

if __name__ == "__main__":
    # sys.argv[1] = Demanda JSON
    # sys.argv[2] = Padrões JSON
    # sys.argv[3] = Caminho absoluto de saída do JSON
    demanda_data = json.loads(sys.argv[1])
    padroes_data = json.loads(sys.argv[2])
    caminho_saida = sys.argv[3]
    
    resolver_pcu(demanda_data, padroes_data, caminho_saida)