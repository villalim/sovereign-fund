"""Main Debug - Versão Simples para Testar"""

import sys
import logging
from pathlib import Path

# ========== SETUP ==========
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)

# Handler para ver em tempo real
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
console_handler.setFormatter(formatter)

logging.basicConfig(level=logging.DEBUG, handlers=[console_handler])
logger = logging.getLogger(__name__)

print("\n" + "=" * 60)
print("🚀 INICIANDO MAIN_DEBUG")
print("=" * 60 + "\n")

try:
    logger.info("Step 1: Importando FastAPI...")
    from fastapi import FastAPI
    logger.info("✓ FastAPI OK")
    
    logger.info("Step 2: Importando settings...")
    from config.settings import settings
    logger.info(f"✓ Settings OK (PORT={settings.BACKEND_PORT})")
    
    logger.info("Step 3: Criando aplicação...")
    app = FastAPI(title="EA Dashboard", version="1.0.0")
    logger.info("✓ App criada")
    
    logger.info("Step 4: Adicionando routes simples...")
    @app.get("/")
    async def root():
        return {"message": "OK"}
    
    @app.get("/health")
    async def health():
        return {"status": "healthy"}
    
    logger.info("✓ Routes adicionadas")
    
    logger.info("Step 5: Preparando para rodar Uvicorn...")
    
    import uvicorn
    logger.info("✓ Uvicorn importado")
    
    logger.info(f"\n{'=' * 60}")
    logger.info(f"🚀 Backend iniciando...")
    logger.info(f"   URL: http://{settings.BACKEND_HOST}:{settings.BACKEND_PORT}")
    logger.info(f"   Docs: http://localhost:{settings.BACKEND_PORT}/docs")
    logger.info(f"{'=' * 60}\n")
    
    # Rodar com log_level mais detalhado
    uvicorn.run(
        app,
        host=settings.BACKEND_HOST,
        port=settings.BACKEND_PORT,
        log_level="debug"
    )
    
except Exception as e:
    logger.error(f"❌ ERRO: {str(e)}", exc_info=True)
    sys.exit(1)