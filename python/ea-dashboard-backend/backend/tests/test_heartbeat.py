import requests
import json
from datetime import datetime

print("=" * 50)
print("TESTE 4: Heartbeat Recebimento")
print("=" * 50)

# Simular heartbeat do EA
heartbeat_data = {
    "timestamp": datetime.now().isoformat(),
    "timestamp_unix": int(datetime.now().timestamp()),
    "instance_id": "TEST_EURUSD_12345",
    "account_number": "12345",
    "account_name": "Test Account",
    "server_name": "MetaTrader 5",
    "symbol": "EURUSD",
    "balance": 10000.00,
    "equity": 10050.00,
    "free_margin": 9500.00,
    "margin_used": 500.00,
    "margin_level": 2010.0,
    "ask": 1.0950,
    "bid": 1.0945,
    "spread": 50,
    "open_positions": 2,
    "is_connected": True,
    "ea_version": "5.02",
    "session_start_time": datetime.now().isoformat(),
    "strategies": [
        {
            "name": "3BullGoDown",
            "enabled": True,
            "last_signal": "NONE",
            "last_signal_time": None,
            "total_trades_today": 0,
            "open_trades": 2
        }
    ],
    "open_trades": [
        {
            "ticket": 123456,
            "strategy": "3BullGoDown",
            "symbol": "EURUSD",
            "type": "BUY",
            "volume": 0.50,
            "entry_price": 1.0940,
            "entry_time": datetime.now().isoformat(),
            "stop_loss": 1.0920,
            "take_profit": 1.0970,
            "current_price": 1.0950,
            "unrealized_pnl": 50.00,
            "magic_number": 10003
        }
    ],
    "daily_stats": {
        "trades_count": 5,
        "trades_won": 3,
        "trades_lost": 2,
        "gross_profit": 500.00,
        "gross_loss": -100.00,
        "net_profit": 50.00,
        "win_rate": 60.0,
        "max_drawdown": 2.5
    }
}

try:
    response = requests.post(
        "http://localhost:5000/heartbeat",
        json=heartbeat_data,
        timeout=5,
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        print("✅ Heartbeat recebido com sucesso pelo backend")
        print(f"Response: {response.json()}")
    else:
        print(f"❌ Backend retornou erro: {response.status_code}")
        print(f"Response: {response.text}")
        
except Exception as e:
    print(f"❌ Erro ao enviar heartbeat: {e}")

print("=" * 50)