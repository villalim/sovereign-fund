from pydantic_settings import BaseSettings
from pathlib import Path
from typing import Optional

class Settings(BaseSettings):
    """Configurações da aplicação FastAPI"""
    
    # Backend
    BACKEND_PORT: int = 8000
    BACKEND_HOST: str = "0.0.0.0"
    DEBUG: bool = True
    
    # Database
    DATABASE_URL: str = "sqlite:///./data.db"
    DATABASE_ECHO: bool = False
    
    # Frontend
    FRONTEND_URL: str = "http://localhost:3000"
    
    # WebSocket
    WEBSOCKET_PING_INTERVAL: int = 30
    WEBSOCKET_PING_TIMEOUT: int = 10
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "logs/backend.log"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Instância global
settings = Settings()

# Debug: Imprimir configurações
if settings.DEBUG:
    print(f"✅ Configurações carregadas: {settings.model_dump()}")