import pytest
import asyncio
from datetime import datetime
from httpx import AsyncClient
from fastapi import FastAPI

# Import da app
import sys
sys.path.insert(0, str(__file__).rsplit('/', 2)[0])
from main import app

@pytest.mark.asyncio
async def test_health_check():
    """Testar endpoint de health check"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_heartbeat_payload():
    """Testar recebimento de heartbeat válido"""
    payload = {
        "timestamp": datetime.utcnow().isoformat(),
        "instanceId": "EA-TEST-001",
        "accountNumber": 12345,
        "symbol": "XAUUSD",
        "eaVersion": "5.02",
        "status": "online",
        "account": {
            "equity": 45320.00,
            "balance": 45100.00,
            "freeMargin": 30500.00,
            "marginLevel": 148.5
        },
        "daily": {
            "startEquity": 43500.00,
            "startBalance": 43200.00,
            "pnlAmount": 850.00,
            "pnlPercent": 1.97,
            "maxDrawdown": 2.5,
            "tradesExecuted": 7,
            "tradesWon": 5,
            "tradesLost": 2,
            "winRate": 71.43
        },
        "positions": {
            "openCount": 3,
            "totalExposure": 7200.00,
            "totalRisk": 450.00
        },
        "strategies": [
            {
                "name": "3BullGoDown",
                "enabled": True,
                "status": "active",
                "lastSignal": {
                    "type": "SELL",
                    "time": datetime.utcnow().isoformat(),
                    "sequence": 3,
                    "valid": True
                },
                "openTrades": 2,
                "dailyPnL": 480.00
            }
        ],
        "riskLimits": {
            "dailyLossLimit": 300.00,
            "dailyLossUsed": 75.00,
            "dailyProfitTarget": 4000.00,
            "dailyProfitAchieved": 850.00,
            "maxExposure": 10000.00,
            "exposureUsed": 7200.00,
            "riskStatus": "healthy"
        }
    }
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/ea/heartbeat", json=payload)
        assert response.status_code == 200
        assert response.json()["status"] == "accepted"
        assert response.json()["instanceId"] == "EA-TEST-001"

@pytest.mark.asyncio
async def test_invalid_heartbeat():
    """Testar rejeição de heartbeat inválido"""
    invalid_payload = {
        "timestamp": "invalid-date",
        "instanceId": "EA-TEST-002"
        # Faltam campos obrigatórios
    }
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/ea/heartbeat", json=invalid_payload)
        assert response.status_code == 422  # Validation error