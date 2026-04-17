# upgrade_fase4_to_fase5b.py

import sqlite3

# Conectar ao banco de dados
conn = sqlite3.connect('database.db')
cursor = conn.cursor()

# Verificar se a tabela instances existe (assumindo fase4)
# Se não, criar tabelas para fase5b

# SQL para criar tabela instances
sql_create_instances = (
    "CREATE TABLE IF NOT EXISTS instances (" +
    "id INTEGER PRIMARY KEY AUTOINCREMENT," +
    "name TEXT NOT NULL," +
    "status TEXT DEFAULT 'active'," +
    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
)

# SQL para criar tabela commands
sql_create_commands = (
    "CREATE TABLE IF NOT EXISTS commands (" +
    "id INTEGER PRIMARY KEY AUTOINCREMENT," +
    "instance_id INTEGER," +
    "command TEXT NOT NULL," +
    "response TEXT," +
    "status TEXT DEFAULT 'pending'," +
    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP," +
    "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP," +
    "FOREIGN KEY (instance_id) REFERENCES instances (id))"
)

# Executar SQLs
cursor.execute(sql_create_instances)
cursor.execute(sql_create_commands)

# Assumir migração: se há dados em fase4, migrar (exemplo simples, ajustar conforme necessário)
# Exemplo: supondo tabela old_instances em fase4
try:
    cursor.execute("SELECT name FROM old_instances")
    old_instances = cursor.fetchall()
    for instance in old_instances:
        cursor.execute("INSERT INTO instances (name) VALUES (?)", (instance[0],))
    print("Migração concluída.")
except sqlite3.OperationalError:
    print("Nenhuma tabela old_instances encontrada, pulando migração.")

# Commit e fechar
conn.commit()
conn.close()

print("Upgrade para fase5b concluído.")


# main_v5b.py

from fastapi import FastAPI, HTTPException, WebSocket
from fastapi.responses import JSONResponse
import sqlite3
import json
from datetime import datetime
from typing import List, Dict

app = FastAPI()

# Inicializar SQLite
def init_db():
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    # SQL para criar tabelas se não existirem
    sql_instances = (
        "CREATE TABLE IF NOT EXISTS instances (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT," +
        "name TEXT NOT NULL," +
        "status TEXT DEFAULT 'active'," +
        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
    )
    sql_commands = (
        "CREATE TABLE IF NOT EXISTS commands (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT," +
        "instance_id INTEGER," +
        "command TEXT NOT NULL," +
        "response TEXT," +
        "status TEXT DEFAULT 'pending'," +
        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP," +
        "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP," +
        "FOREIGN KEY (instance_id) REFERENCES instances (id))"
    )
    cursor.execute(sql_instances)
    cursor.execute(sql_commands)
    conn.commit()
    conn.close()

init_db()

# Endpoint GET /heartbeat
@app.get("/heartbeat")
async def heartbeat():
    return {"status": "ok"}

# Endpoint GET /instances
@app.get("/instances")
async def get_instances():
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, status, created_at FROM instances")
    instances = cursor.fetchall()
    conn.close()
    return [{"id": i[0], "name": i[1], "status": i[2], "created_at": i[3]} for i in instances]

# Endpoint POST /commands
@app.post("/commands")
async def create_command(command: Dict[str, str]):
    instance_id = command.get("instance_id")
    cmd = command.get("command")
    if not instance_id or not cmd:
        raise HTTPException(status_code=400, detail="instance_id and command required")
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    cursor.execute("INSERT INTO commands (instance_id, command) VALUES (?, ?)", (instance_id, cmd))
    command_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return {"id": command_id, "status": "created"}

# Endpoint GET /commands/{id}
@app.get("/commands/{command_id}")
async def get_command(command_id: int):
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    cursor.execute("SELECT id, instance_id, command, response, status, created_at, updated_at FROM commands WHERE id = ?", (command_id,))
    command = cursor.fetchone()
    conn.close()
    if not command:
        raise HTTPException(status_code=404, detail="Command not found")
    return {
        "id": command[0],
        "instance_id": command[1],
        "command": command[2],
        "response": command[3],
        "status": command[4],
        "created_at": command[5],
        "updated_at": command[6]
    }

# Endpoint POST /commands/response
@app.post("/commands/response")
async def update_command_response(response_data: Dict[str, str]):
    command_id = response_data.get("command_id")
    response = response_data.get("response")
    if not command_id or not response:
        raise HTTPException(status_code=400, detail="command_id and response required")
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    cursor.execute("UPDATE commands SET response = ?, status = 'completed', updated_at = CURRENT_TIMESTAMP WHERE id = ?", (response, command_id))
    conn.commit()
    conn.close()
    return {"status": "updated"}

# WebSocket /ws
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_text()
        # Exemplo simples: ecoar dados
        await websocket.send_text(f"Echo: {data}")

# Para rodar: uvicorn main_v5b:app --reload


# app_v5b.py

import streamlit as st
import requests
import pandas as pd

# Configurar página
st.set_page_config(page_title="Dashboard Fase5b", layout="wide")

# Tabs
tab1, tab2, tab3 = st.tabs(["KPIs", "Instâncias", "Comandos"])

# Função para obter dados da API
BASE_URL = "http://localhost:8000"

def get_instances():
    response = requests.get(f"{BASE_URL}/instances")
    return response.json() if response.status_code == 200 else []

def get_commands():
    # Assumir endpoint para listar comandos, ajustar se necessário
    # Como não há GET /commands, simular ou adicionar
    # Para simplicidade, retornar lista vazia
    return []

def send_command(instance_id, command):
    response = requests.post(f"{BASE_URL}/commands", json={"instance_id": instance_id, "command": command})
    return response.json() if response.status_code == 200 else {"error": "Failed"}

# Tab KPIs
with tab1:
    st.header("KPIs")
    instances = get_instances()
    num_instances = len(instances)
    # Calcular outros KPIs, ex: comandos pendentes
    # Para simplicidade, apenas num_instances
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Número de Instâncias", num_instances)
    with col2:
        st.metric("Comandos Pendentes", 0)  # Placeholder
    with col3:
        st.metric("Total de Comandos", 0)  # Placeholder

# Tab Instâncias
with tab2:
    st.header("Instâncias")
    instances = get_instances()
    if instances:
        df = pd.DataFrame(instances)
        st.dataframe(df)
    else:
        st.write("Nenhuma instância encontrada.")

# Tab Comandos
with tab3:
    st.header("Comandos")
    # Formulário para enviar comando
    with st.form("send_command_form"):
        instance_id = st.selectbox("Selecionar Instância", [i["id"] for i in get_instances()])
        command = st.text_area("Comando")
        submitted = st.form_submit_button("Enviar Comando")
        if submitted:
            result = send_command(instance_id, command)
            st.write(result)
    # Lista de comandos (placeholder)
    commands = get_commands()
    if commands:
        df = pd.DataFrame(commands)
        st.dataframe(df)
    else:
        st.write("Nenhum comando encontrado.")

# Para rodar: streamlit run app_v5b.py