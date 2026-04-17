from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from enum import Enum

class StrategyStatus(str, Enum):
    """Status possível de uma estratégia"""
    ACTIVE = "active"
    DISABLED = "disabled"
    WAITING = "waiting"
    ERROR = "error"

class TradeType(str, Enum):
    """Tipo de trade"""
    BUY = "BUY"
    SELL = "SELL"

class SignalInfo(BaseModel):
    """Informação de sinal gerado"""
    type: TradeType
    time: datetime
    sequence: Optional[int] = None
    valid: bool

class StrategyMetrics(BaseModel):
    """Métricas de uma estratégia"""
    name: str
    enabled: bool
    status: StrategyStatus
    lastSignal: Optional[SignalInfo] = None
    openTrades: int
    dailyPnL: float

class AccountMetrics(BaseModel):
    """Métricas da conta"""
    equity: float
    balance: float
    freeMargin: float
    marginLevel: float

class DailyMetrics(BaseModel):
    """Métricas diárias"""
    startEquity: float
    startBalance: float
    pnlAmount: float
    pnlPercent: float
    maxDrawdown: float
    tradesExecuted: int
    tradesWon: int
    tradesLost: int
    winRate: float

class PositionMetrics(BaseModel):
    """Métricas de posições"""
    openCount: int
    totalExposure: float
    totalRisk: float

class RiskLimits(BaseModel):
    """Limites de risco"""
    dailyLossLimit: float
    dailyLossUsed: float
    dailyProfitTarget: float
    dailyProfitAchieved: float
    maxExposure: float
    exposureUsed: float
    riskStatus: str  # "healthy", "warning", "critical"

class HeartbeatPayload(BaseModel):
    """Payload completo do heartbeat do EA"""
    timestamp: datetime
    instanceId: str = Field(..., description="ID único da instância EA")
    accountNumber: int
    symbol: str
    eaVersion: str
    status: str  # "online", "offline", "error"
    
    account: AccountMetrics
    daily: DailyMetrics
    positions: PositionMetrics
    strategies: List[StrategyMetrics]
    riskLimits: RiskLimits
    
    class Config:
        json_schema_extra = {
            "example": {
                "timestamp": "2025-04-12T12:45:23.456Z",
                "instanceId": "EA-INSTANCE-001",
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
                            "time": "2025-04-12T12:45:00Z",
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
        }