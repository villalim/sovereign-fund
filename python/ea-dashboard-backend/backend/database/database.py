from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import StaticPool
from pathlib import Path
import logging
from config.settings import settings
from .models import Base

logger = logging.getLogger(__name__)

# Construir URL assíncrona para SQLite
DATABASE_URL = f"sqlite+aiosqlite:///{Path('data').absolute() / 'dashboard.db'}"

# Configurar engine
engine = create_async_engine(
    DATABASE_URL,
    echo=settings.DATABASE_ECHO,
    future=True,
    poolclass=StaticPool,
    connect_args={"check_same_thread": False}
)

# Criar SessionLocal para operações
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

async def init_db():
    """Inicializar banco de dados (criar tabelas)"""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("✅ Banco de dados inicializado com sucesso")
    except Exception as e:
        logger.error(f"❌ Erro ao inicializar BD: {str(e)}")
        raise

async def get_db() -> AsyncSession:
    """Dependency injection para obter sessão do BD"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

async def close_db():
    """Fechar conexões com BD"""
    await engine.dispose()
    logger.info("✅ Conexões BD fechadas")