import sys
sys.path.insert(0, r'C:\Users\evila\ea-dashboard-backend\fase4')

import streamlit as st
import requests
import json

st.title("Dashboard Fase 4")

# Conexão ao backend
backend_url = "http://127.0.0.1:8000"

if st.button("Check Health"):
    try:
        response = requests.get(f"{backend_url}/health")
        st.success(response.json())
    except:
        st.error("Backend não está rodando")

with st.form("Add Item"):
    name = st.text_input("Name")
    value = st.text_input("Value")
    submitted = st.form_submit_button("Add")
    if submitted:
        try:
            response = requests.post(f"{backend_url}/items", json={"name": name, "value": value})
            st.success(response.json())
        except:
            st.error("Erro ao adicionar item")

if st.button("Get Items"):
    try:
        response = requests.get(f"{backend_url}/items")
        st.json(response.json())
    except:
        st.error("Erro ao obter items")
