from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class TradeData(BaseModel):
    """Dados de um trade executado"""
    type: str  # "BUY" ou "SELL"
    symbol: str
    volume: float
    entryPrice: float
    stopLoss: float
    takeProfit: float
    strategy: str
    magicNumber: int
    openTime: datetime
    riskAmount: float
    riskPercent: float

class ValidationDetails(BaseModel):
    """Detalhes da validação do sinal"""
    minSequence: str
    bodySize: str
    wickRatio: str

class TradeDecision(BaseModel):
    """Decisão e validação do trade"""
    sequence: int
    bodySize: float
    upperWick: float
    lowerWick: float
    validationResult: str  # "PASSED", "FAILED"
    validationDetails: ValidationDetails

class TradePayload(BaseModel):
    """Payload de execução de trade"""
    timestamp: datetime
    instanceId: str
    eventType: str  # "TRADE_OPENED", "TRADE_CLOSED"
    tradeId: int
    
    trade: TradeData
    decision: TradeDecision