import pulp
import sys
import json
import os

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
        
    # Garante que o PuLP localize o solver CBC nativo de dentro do executável PyInstaller
    try:
        path_to_cbc = pulp.packaging.cbc_path
        solver = pulp.PULP_CBC_CMD(path=path_to_cbc, msg=False)
        status = prob.solve(solver)
    except Exception:
        status = prob.solve(pulp.PULP_CBC_CMD(msg=0))
    
    status_string = pulp.LpStatus[status]
    
    resultado = {
        "status": status_string,
        "solucao": [int(pulp.value(x[j])) for j in range(num_padroes)] if status_string == "Optimal" else []
    }
    
    with open(caminho_saida, "w") as f:
        json.dump(resultado, f)
    sys.exit(0)

if __name__ == "__main__":
    if getattr(sys, 'frozen', False):
        base_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        

    caminho_saida_dinamico = os.path.join(base_dir, "resolve_modelagem.json")

    args = [a for a in sys.argv[1:] if a.strip()]

    if len(args) < 2:
        sys.exit(1) # Evita travamento caso falte parâmetros de envio do motor do jogo
        
    try:
        demanda_data = json.loads(args[0])
        padroes_data = json.loads(args[1])
        resolver_pcu(demanda_data, padroes_data, caminho_saida_dinamico)
    except Exception:
        sys.exit(1)
