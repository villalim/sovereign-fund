import streamlit as st
import requests
import asyncio
import websockets

st.title("Dashboard Simples")

# Conexão ao backend
backend_url = "http://localhost:8000"

# Função para conectar ao WebSocket
async def connect_websocket():
    uri = "ws://localhost:8000/ws"
    async with websockets.connect(uri) as websocket:
        await websocket.send("Hello from Streamlit!")
        response = await websocket.recv()
        st.write(f"Resposta do WebSocket: {response}")

if st.button("Testar WebSocket"):
    asyncio.run(connect_websocket())

# Buscar itens
if st.button("Buscar Itens"):
    response = requests.get(f"{backend_url}/items/")
    if response.status_code == 200:
        items = response.json()
        st.write(items)
    else:
        st.error("Erro ao buscar itens")

# Criar item
name = st.text_input("Nome")
description = st.text_input("Descrição")
if st.button("Criar Item"):
    data = {"name": name, "description": description}
    response = requests.post(f"{backend_url}/items/", json=data)
    if response.status_code == 200:
        st.success("Item criado!")
    else:
        st.error("Erro ao criar item")
