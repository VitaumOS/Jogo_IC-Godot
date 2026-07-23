import pulp as p
import sys
import json 
import os

def parse_list_string(s: str) -> list[float]:
    # Limpa colchetes, espaços e aspas comuns gerados pelo envio do Godot
    s = s.strip().replace('[', '').replace(']', '').replace('"', '').replace("'", "")
    if not s:
        return []
    return [float(x.strip()) for x in s.split(',') if x.strip()]

def resolver_pcu_pl(demanda_qtd: list[float], padroes_qtd: list[list[float]], output_path: str):
    num_tipos_peca = len(demanda_qtd)
    num_padroes = len(padroes_qtd)
    
    if num_tipos_peca == 0 or num_padroes == 0:
        sys.exit(1)

    tipos_peca = [f"Peca_{i+1}" for i in range(num_tipos_peca)]
    nomes_padroes = [f"Padrao_{j+1}" for j in range(num_padroes)]
    demanda = {tipos_peca[i]: demanda_qtd[i] for i in range(num_tipos_peca)}
    
    prob = p.LpProblem("ProblemaDeCorteDeEstoque", p.LpMinimize)
    variaveis_x = p.LpVariable.dicts("UsoPadrao", nomes_padroes, lowBound=0, cat=p.LpInteger)
    
    prob += p.lpSum([variaveis_x[j] for j in nomes_padroes]), "Total_Chapas_Usadas"
    
    for i, peca in enumerate(tipos_peca):
        prob += p.lpSum([padroes_qtd[j][i] * variaveis_x[nomes_padroes[j]] for j in range(num_padroes)]) >= demanda[peca], \
            f"Restricao_{peca}"
            
    # FORÇA o PuLP a rodar usando a engine nativa estável do CMD
    try:
        prob.solve(p.PULP_CBC_CMD(msg=False, options=["presolve off","maxIt=100"]))
    except Exception:
        # Fallback caso o solver padrão do CMD falhe dentro do ambiente compilado
        prob.solve(p.COIN_CMD(msg=False, options=["presolve off","maxIt=100"]))
        
    resultado = {}
    if p.LpStatus[prob.status] == "Optimal":
        resultado['status'] = "Optimal"
        resultado['chapas_usadas'] = int(p.value(prob.objective))
        plano_corte = {nome_padrao: int(p.value(variaveis_x[nome_padrao])) for nome_padrao in nomes_padroes if p.value(variaveis_x[nome_padrao]) > 0}
        resultado['plano_corte'] = plano_corte
    else:
        resultado['status'] = p.LpStatus[prob.status]
        resultado['erro_detalhe'] = f"Falha no solver"
        
    with open(output_path, 'w') as f:
        json.dump(resultado, f, indent=4)
    sys.exit(0)

if __name__ == '__main__':
    if getattr(sys, 'frozen', False):
        base_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        
    output_full_path = os.path.join(base_dir, "pulp_solution.json")

    # Filtra argumentos para ignorar ruídos de chamadas externas do sistema
    args = [a for a in sys.argv[1:] if a.strip()]
    
    if len(args) < 2:
        sys.exit(1) # Impede travamentos se os dados vierem vazios
        
    try:
        demanda_qtd = parse_list_string(args[0])
        padroes_qtd = [parse_list_string(args[i]) for i in range(1, len(args))]
        resolver_pcu_pl(demanda_qtd, padroes_qtd, output_full_path)
    except Exception:
        sys.exit(1)
