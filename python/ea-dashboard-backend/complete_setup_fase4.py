import os
import sys
import subprocess
import shutil
from pathlib import Path

# Cores ANSI
def green(text):
    return f'\033[92m{text}\033[0m'

def red(text):
    return f'\033[91m{text}\033[0m'

def yellow(text):
    return f'\033[93m{text}\033[0m'

# Função para criar estrutura de pastas
def create_structure():
    base_dir = os.path.abspath('fase4')
    backend_dir = os.path.join(base_dir, 'backend')
    dashboard_dir = os.path.join(base_dir, 'dashboard')
    
    os.makedirs(backend_dir, exist_ok=True)
    os.makedirs(dashboard_dir, exist_ok=True)
    
    print(green(f'Estrutura de pastas criada em: {base_dir}'))
    return base_dir, backend_dir, dashboard_dir

# Função para criar requirements.txt
def create_requirements(base_dir):
    req_path = os.path.join(base_dir, 'requirements.txt')
    requirements = '''fastapi==0.104.1
uvicorn[standard]==0.24.0
streamlit==1.28.1
requests==2.31.0
websockets==12.0
'''
    with open(req_path, 'w') as f:
        f.write(requirements)
    print(green(f'requirements.txt criado em: {req_path}'))

# Função para instalar dependências
def install_deps(base_dir):
    req_path = os.path.join(base_dir, 'requirements.txt')
    try:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', req_path])
        print(green('Dependências instaladas com sucesso.'))
    except subprocess.CalledProcessError as e:
        print(red(f'Erro ao instalar dependências: {e}'))

# Função para criar backend/main.py
def create_backend(backend_dir, base_dir):
    main_py = os.path.join(backend_dir, 'main.py')
    code = f'''import sys
sys.path.insert(0, r'{base_dir}')

from fastapi import FastAPI, WebSocket
from typing import List
import json

app = FastAPI()

items = []

@app.get("/health")
def health():
    return {{"status": "ok"}}

@app.get("/items")
def get_items():
    return {{"items": items}}

@app.post("/items")
def add_item(item: dict):
    items.append(item)
    return {{"message": "Item added", "item": item}}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_text()
        await websocket.send_text(f"Echo: {{data}}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
'''
    with open(main_py, 'w') as f:
        f.write(code)
    print(green(f'Backend criado em: {main_py}'))

# Função para criar dashboard/app.py
def create_dashboard(dashboard_dir, base_dir):
    app_py = os.path.join(dashboard_dir, 'app.py')
    code = f'''import sys
sys.path.insert(0, r'{base_dir}')

import streamlit as st
import requests
import json

st.title("Dashboard Fase 4")

# Conexão ao backend
backend_url = "http://127.0.0.1:8000"

if st.button("Check Health"):
    try:
        response = requests.get(f"{{backend_url}}/health")
        st.success(response.json())
    except:
        st.error("Backend não está rodando")

with st.form("Add Item"):
    name = st.text_input("Name")
    value = st.text_input("Value")
    submitted = st.form_submit_button("Add")
    if submitted:
        try:
            response = requests.post(f"{{backend_url}}/items", json={{"name": name, "value": value}})
            st.success(response.json())
        except:
            st.error("Erro ao adicionar item")

if st.button("Get Items"):
    try:
        response = requests.get(f"{{backend_url}}/items")
        st.json(response.json())
    except:
        st.error("Erro ao obter items")
'''
    with open(app_py, 'w') as f:
        f.write(code)
    print(green(f'Dashboard criado em: {app_py}'))

# Função para rodar backend
def run_backend(backend_dir):
    main_py = os.path.join(backend_dir, 'main.py')
    try:
        process = subprocess.Popen([sys.executable, main_py], cwd=backend_dir)
        print(green(f'Backend rodando em processo PID: {process.pid}'))
        return process
    except Exception as e:
        print(red(f'Erro ao rodar backend: {e}'))
        return None

# Função para rodar dashboard
def run_dashboard(dashboard_dir):
    app_py = os.path.join(dashboard_dir, 'app.py')
    try:
        process = subprocess.Popen([sys.executable, '-m', 'streamlit', 'run', app_py], cwd=dashboard_dir)
        print(green(f'Dashboard rodando em processo PID: {process.pid}'))
        return process
    except Exception as e:
        print(red(f'Erro ao rodar dashboard: {e}'))
        return None

# Menu principal
def main():
    print(yellow('Setup Fase 4 - Iniciando...'))
    base_dir, backend_dir, dashboard_dir = create_structure()
    create_requirements(base_dir)
    install_deps(base_dir)
    create_backend(backend_dir, base_dir)
    create_dashboard(dashboard_dir, base_dir)
    
    while True:
        print('\n' + yellow('Menu:'))
        print('1. Rodar Backend')
        print('2. Rodar Dashboard')
        print('3. Sair')
        choice = input('Escolha: ')
        if choice == '1':
            run_backend(backend_dir)
        elif choice == '2':
            run_dashboard(dashboard_dir)
        elif choice == '3':
            break
        else:
            print(red('Opção inválida'))

if __name__ == '__main__':
    main()
