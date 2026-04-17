import streamlit as st
import requests

st.title("Dashboard Fase 5B")

if st.button("Chamar API Backend"):
    try:
        response = requests.get("http://localhost:8000/")
        st.write(response.json())
    except Exception as e:
        st.write(f"Erro: {e}")
