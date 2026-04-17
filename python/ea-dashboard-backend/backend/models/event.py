from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any

class EventPayload(BaseModel):
    """Payload genérico de evento estruturado"""
    timestamp: datetime
    instanceId: str
    eventType: str  # "SIGNAL_GENERATED", "TRADE_OPENED", etc
    severity: str  # "INFO", "WARNING", "ERROR", "CRITICAL"
    message: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None  # JSON flexível