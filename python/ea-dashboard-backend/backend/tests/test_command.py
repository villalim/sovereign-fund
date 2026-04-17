import requests
import json

print("=" * 50)
print("TESTE 5: Command Listener")
print("=" * 50)

# Simular comando do backend
command_data = {
    "type": 1,  # CMD_START_STRATEGY
    "command_id": "cmd_12345_001",
    "strategy": "3BullGoDown",
    "param_name": None,
    "param_value": None,
    "pause_minutes": None,
    "daily_profit_limit": None,
    "daily_loss_limit": None,
    "trailing_percent": None
}

try:
    # Backend envia comando para EA
    response = requests.get(
        "http://localhost:5000/commands",
        timeout=5
    )
    
    if response.status_code == 200:
        print("✅ EA conseguiu buscar comando")
        print(f"Response: {response.json()}")
    else:
        print(f"❌ Erro: {response.status_code}")
        
except Exception as e:
    print(f"❌ Erro: {e}")

print("=" * 50)