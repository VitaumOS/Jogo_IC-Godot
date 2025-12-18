import pulp as p
import sys
import json 
import os


OUTPUT_FILE_NAME = "pulp_solution.json" 

def parse_list_string(s: str) -> list[float]:
    s = s.strip().strip('[]')
    if not s:
        return []
    return [float(x.strip()) for x in s.split(',')]

def resolver_pcu_pl(demanda_qtd: list[float], padroes_qtd: list[list[float]]):

    num_tipos_peca = len(demanda_qtd)
    num_padroes = len(padroes_qtd)
    
    tipos_peca = [f"Peca_{i+1}" for i in range(num_tipos_peca)]
    nomes_padroes = [f"Padrão_{j+1}" for j in range(num_padroes)]
    
    demanda = {tipos_peca[i]: demanda_qtd[i] for i in range(num_tipos_peca)}
    
    prob = p.LpProblem("ProblemaDeCorteDeEstoque", p.LpMinimize)
    variaveis_x = p.LpVariable.dicts("UsoPadrao", nomes_padroes, lowBound=0, cat=p.LpInteger)
    
    # Função Objetivo
    prob += p.lpSum([variaveis_x[j] for j in nomes_padroes]), "Total_Chapas_Usadas"
    
    # Restrições 
    for i, peca in enumerate(tipos_peca):
        prob += p.lpSum([padroes_qtd[j][i] * variaveis_x[nomes_padroes[j]] for j in range(num_padroes)]) >= demanda[peca], \
            f"Restricao_{peca}"
            
    prob.solve(p.PULP_CBC_CMD(options=["presolve off","maxIt=100"]))
    resultado = {}

    if p.LpStatus[prob.status] == "Optimal":
        resultado['status'] = "Optimal"
        resultado['chapas_usadas'] = int(p.value(prob.objective))
        
        plano_corte = {}
        for nome_padrao in nomes_padroes:
            uso = p.value(variaveis_x[nome_padrao])
            # Salva APENAS os padrões utilizados
            if uso > 0:
                plano_corte[nome_padrao] = int(uso)
        
        resultado['plano_corte'] = plano_corte
        
    else:
        resultado['status'] = p.LpStatus[prob.status]
        resultado['erro_detalhe'] = f"PuLP não encontrou solução ótima: {p.LpStatus[prob.status]}"
        
    # Salva o resultado no arquivo JSON
    with open(OUTPUT_FILE_NAME, 'w') as f:
        json.dump(resultado, f, indent=4)
    sys.exit(0)

if __name__ == '__main__':
    
    if len(sys.argv) > 1:
        args = sys.argv[1:]  
    try:
        demanda_string = args[0]
        demanda_qtd = parse_list_string(demanda_string)
        
        padroes_qtd = []
        for i in range(1, len(args)):
            padrao_string = args[i]
            padroes_qtd.append(parse_list_string(padrao_string))

    except Exception as e:
        sys.stderr.write(f"Falha ao converter string para lista numérica. {e}")
        sys.exit(1)
    
    resolver_pcu_pl(demanda_qtd, padroes_qtd)