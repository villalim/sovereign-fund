import requests
import sys
import uuid

if len(sys.argv) != 2:
    print("Uso: python script.py <command_type>")
    print("Onde <command_type> é um inteiro de 1 a 8")
    sys.exit(1)

try:
    command_type = int(sys.argv[1])
    if not 1 <= command_type <= 8:
        raise ValueError
except ValueError:
    print("Erro: command_type deve ser um inteiro entre 1 e 8")
    sys.exit(1)

# Gerar command_id único
command_id = str(uuid.uuid4())

# URL do EA (ajuste conforme necessário)
url = "http://localhost:8080/command"

# Payload do comando
payload = {
    "command": "START_STRATEGY",
    "strategy": "3BullGoDown",
    "command_id": command_id,
    "type": command_type
}

try:
    response = requests.post(url, json=payload)
    print(f"Comando enviado. Status: {response.status_code}")
    print(f"Resposta: {response.text}")
except requests.exceptions.RequestException as e:
    print(f"Erro ao enviar comando: {e}")