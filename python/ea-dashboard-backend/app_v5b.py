import streamlit as st
import requests
import pandas as pd

# Configurações do backend
BACKEND_URL = 'http://localhost:8000'  # Ajuste conforme necessário

# Função para verificar status do backend
def check_backend_status():
    try:
        response = requests.get(f'{BACKEND_URL}/health', timeout=5)
        if response.status_code == 200:
            return True
        else:
            return False
    except requests.exceptions.RequestException:
        return False

# Função para obter instâncias
def get_instances():
    try:
        response = requests.get(f'{BACKEND_URL}/instances', timeout=10)
        if response.status_code == 200:
            data = response.json()
            return data if data else []
        else:
            st.error(f'Erro ao obter instâncias: {response.status_code}')
            return []
    except requests.exceptions.RequestException as e:
        st.error(f'Erro de conexão ao obter instâncias: {str(e)}')
        return []

# Função para enviar comando
def send_command(command_data):
    try:
        response = requests.post(f'{BACKEND_URL}/commands', json=command_data, timeout=10)
        if response.status_code == 200:
            st.success('Comando enviado com sucesso!')
        else:
            st.error(f'Erro ao enviar comando: {response.status_code}')
    except requests.exceptions.RequestException as e:
        st.error(f'Erro de conexão ao enviar comando: {str(e)}')

# Interface principal
st.title('Dashboard de Instâncias')

# Sidebar com status do backend
with st.sidebar:
    st.header('Status do Backend')
    if check_backend_status():
        st.success('Backend Online')
    else:
        st.error('Backend Offline')

# Tabs
tab1, tab2, tab3 = st.tabs(['KPIs', 'Instâncias', 'Comandos'])

with tab1:
    st.header('KPIs (Dados Fictícios para Demo)')
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric('Total de Instâncias', 150)
    with col2:
        st.metric('Instâncias Ativas', 120)
    with col3:
        st.metric('Uptime Médio', '99.5%')

with tab2:
    st.header('Instâncias')
    instances = get_instances()
    if instances:
        df = pd.DataFrame(instances)
        st.dataframe(df)
    else:
        st.info('Nenhuma instância encontrada.')

with tab3:
    st.header('Enviar Comando')
    with st.form('command_form'):
        instance_id = st.text_input('ID da Instância')
        command = st.text_area('Comando')
        submitted = st.form_submit_button('Enviar')
        if submitted:
            if instance_id and command:
                send_command({'instance_id': instance_id, 'command': command})
            else:
                st.warning('Preencha todos os campos.')