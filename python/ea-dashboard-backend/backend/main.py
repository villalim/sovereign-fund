"""
EA Dashboard Backend - Main Entry Point
Versao Simplificada para Semanas 1-2 (sem WebSocket ainda)
"""

import logging
import sys
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
#from routes.zmq_test import router as zmq_test_router
#from routes.zmq_receiver import router as zmq_receiver_router

# ========== LOGGING SETUP ==========

log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_dir / "backend.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

# ========== IMPORTS ==========

logger.info("=" * 60)
logger.info("[STARTUP] Iniciando EA Dashboard Backend")
logger.info("=" * 60)

try:
    from config.settings import settings
    logger.info(f"[OK] Settings carregadas (DEBUG={settings.DEBUG})")
except Exception as e:
    logger.error(f"[ERRO] Falha ao carregar settings: {e}")
    sys.exit(1)

try:
    from database.database import init_db, close_db
    logger.info("[OK] Database module carregado")
except Exception as e:
    logger.error(f"[ERRO] Falha ao carregar database: {e}")
    sys.exit(1)

try:
    from routes.ea_receiver import router as ea_receiver_router
    logger.info("[OK] Routes carregadas")
except Exception as e:
    logger.error(f"[ERRO] Falha ao carregar routes: {e}")
    sys.exit(1)

# ========== CREATE APP ==========

app = FastAPI(
    title="EA Dashboard Backend",
    description="Backend de gestao de Expert Advisor MT5",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

logger.info("[OK] Aplicacao FastAPI criada")

# ========== CORS MIDDLEWARE ==========

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        settings.FRONTEND_URL,
        "http://localhost:3000",
        "http://127.0.0.1:3000"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

logger.info("[OK] CORS middleware configurado")

# ========== EVENT HANDLERS ==========

@app.on_event("startup")
async def startup_event():
    """Executado quando a aplicacao inicia"""
    logger.info("[INIT] Iniciando banco de dados...")
    try:
        await init_db()
        logger.info("[OK] Banco de dados inicializado")
    except Exception as e:
        logger.error(f"[ERRO] Falha ao inicializar BD: {e}")
        raise

@app.on_event("shutdown")
async def shutdown_event():
    """Executado quando a aplicacao encerra"""
    logger.info("[SHUTDOWN] Encerrando aplicacao...")
    try:
        await close_db()
        logger.info("[OK] Banco de dados fechado")
    except Exception as e:
        logger.error(f"[ERRO] Falha ao fechar BD: {e}")

# ========== ROUTES ==========

app.include_router(ea_receiver_router)

logger.info("[OK] Routes registradas")

# ========== HEALTH CHECK ==========

@app.get("/", tags=["Root"])
async def root():
    """Endpoint raiz"""
    return {
        "message": "EA Dashboard Backend API",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", tags=["System"])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": "1.0.0"
    }

logger.info("[OK] Health endpoints configurados")

# ========== MAIN ==========
if __name__ == "__main__":
    import uvicorn
    
    logger.info("\n" + "=" * 60)
    logger.info("[CONFIG] Configuracoes Finais:")
    logger.info(f"   Host: {settings.BACKEND_HOST}")
    logger.info(f"   Port: {settings.BACKEND_PORT}")
    logger.info(f"   Debug: {settings.DEBUG}")
    logger.info(f"   Database: {settings.DATABASE_URL}")
    logger.info("=" * 60 + "\n")
    
    logger.info(f"[URL] Documentacao em: http://localhost:{settings.BACKEND_PORT}/docs")
    logger.info(f"[URL] Health check em: http://localhost:{settings.BACKEND_PORT}/health")
    logger.info("\n[INFO] Pressione CTRL+C para parar o servidor\n")
    
    try:
        uvicorn.run(
            "main:app",
            host=settings.BACKEND_HOST,
            port=settings.BACKEND_PORT,
            reload=settings.DEBUG,
            log_level="info"
        )
    except KeyboardInterrupt:
        logger.info("\n[STOP] Backend interrompido pelo usuario")
    except Exception as e:
        logger.error(f"[ERRO] Falha ao iniciar backend: {e}", exc_info=True)
        sys.exit(1)