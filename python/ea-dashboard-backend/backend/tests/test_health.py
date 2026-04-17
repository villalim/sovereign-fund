import requests
import json
from datetime import datetime

# Test 1: Health Check
print("=" * 50)
print("TESTE 3: Backend Health Check")
print("=" * 50)

try:
    response = requests.post("http://localhost:5000/health", json={"test": True}, timeout=5)
    
    if response.status_code == 200:
        print("✅ Backend está respondendo")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    else:
        print(f"❌ Backend retornou erro: {response.status_code}")
        
except requests.exceptions.ConnectionError:
    print("❌ Não conseguiu conectar ao backend em http://localhost:5000")
    print("   Certifique-se que o backend está rodando:")
    print("   python backend/app.py")
    
except Exception as e:
    print(f"❌ Erro: {e}")

print("=" * 50)