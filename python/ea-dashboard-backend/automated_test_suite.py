import sys
if sys.version_info < (3, 6):
    print('Python 3.6+ é necessário.')
    sys.exit(1)

import os
import subprocess
import time
import json
import datetime
from datetime import datetime as dt
import requests
from colorama import init, Fore, Back, Style

# Inicializar colorama
init(autoreset=True)

# Dependências a instalar
dependencies = ['requests', 'fastapi', 'uvicorn', 'colorama']

# Função para instalar dependências
def install_dependencies():
    print(f'{Fore.GREEN}Verificando e instalando dependências...{Style.RESET_ALL}')
    for dep in dependencies:
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', dep], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f'{Fore.BLUE}Instalado: {dep}{Style.RESET_ALL}')
        except subprocess.CalledProcessError:
            print(f'{Fore.RED}Falha ao instalar {dep}. Verifique sua conexão ou permissões.{Style.RESET_ALL}')
            sys.exit(1)

# Criar estrutura de pastas
def create_structure():
    print(f'{Fore.GREEN}Criando estrutura de pastas...{Style.RESET_ALL}')
    dirs = ['backend', 'logs', 'reports']
    for d in dirs:
        os.makedirs(d, exist_ok=True)
        print(f'{Fore.BLUE}Criado: {d}{Style.RESET_ALL}')

# Criar backend FastAPI mínimo
def create_backend():
    print(f'{Fore.GREEN}Criando backend FastAPI...{Style.RESET_ALL}')
    backend_code = '''
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.get("/test1")
def test1():
    return {"result": "Test 1 OK"}

@app.get("/test2")
def test2():
    return {"result": "Test 2 OK"}

@app.get("/test3")
def test3():
    return {"result": "Test 3 OK"}

@app.get("/test4")
def test4():
    return {"result": "Test 4 OK"}

@app.get("/test5")
def test5():
    return {"result": "Test 5 OK"}

@app.get("/test6")
def test6():
    return {"result": "Test 6 OK"}
'''
    with open(os.path.join('backend', 'app.py'), 'w') as f:
        f.write(backend_code)
    print(f'{Fore.BLUE}Backend criado em backend/app.py{Style.RESET_ALL}')

# Barra de progresso simples
def progress_bar(current, total, width=50):
    percent = current / total
    filled = int(width * percent)
    bar = '█' * filled + '-' * (width - filled)
    print(f'\r[{bar}] {int(percent * 100)}%', end='', flush=True)
    if current == total:
        print()

# Rodar backend em background
def run_backend():
    print(f'{Fore.GREEN}Iniciando backend...{Style.RESET_ALL}')
    process = subprocess.Popen([sys.executable, '-m', 'uvicorn', 'backend.app:app', '--host', '127.0.0.1', '--port', '8000'], cwd=os.getcwd())
    time.sleep(2)  # Aguardar inicialização
    return process

# Testar endpoints
def run_tests():
    print(f'{Fore.GREEN}Executando testes HTTP...{Style.RESET_ALL}')
    base_url = 'http://127.0.0.1:8000'
    endpoints = ['/', '/test1', '/test2', '/test3', '/test4', '/test5', '/test6']
    results = []
    total = len(endpoints)
    for i, ep in enumerate(endpoints, 1):
        try:
            response = requests.get(base_url + ep, timeout=5)
            if response.status_code == 200:
                result = f'{Fore.GREEN}PASS{Style.RESET_ALL}'
            else:
                result = f'{Fore.RED}FAIL (Status: {response.status_code}){Style.RESET_ALL}'
        except Exception as e:
            result = f'{Fore.RED}FAIL (Erro: {str(e)}){Style.RESET_ALL}'
        results.append(f'Endpoint {ep}: {result}')
        progress_bar(i, total)
        time.sleep(0.5)
    return results

# Gerar relatório
def generate_report(results):
    print(f'{Fore.GREEN}Gerando relatório...{Style.RESET_ALL}')
    timestamp = dt.now().strftime('%Y-%m-%d_%H-%M-%S')
    report_file = os.path.join('reports', f'report_{timestamp}.txt')
    log_file = os.path.join('logs', f'log_{timestamp}.txt')
    
    report_content = f'Relatório de Testes - {timestamp}\n\n'
    for res in results:
        report_content += res + '\n'
        print(res)
    
    with open(report_file, 'w') as f:
        f.write(report_content)
    with open(log_file, 'w') as f:
        f.write(report_content)
    
    print(f'{Fore.BLUE}Relatório salvo em: {report_file}{Style.RESET_ALL}')
    print(f'{Fore.BLUE}Logs salvos em: {log_file}{Style.RESET_ALL}')

# Função principal
def main():
    install_dependencies()
    create_structure()
    create_backend()
    backend_process = run_backend()
    try:
        results = run_tests()
        generate_report(results)
    finally:
        backend_process.terminate()
        backend_process.wait()
        print(f'{Fore.GREEN}Backend encerrado.{Style.RESET_ALL}')

if __name__ == '__main__':
    main()
