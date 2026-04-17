from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import insert, select
from datetime import datetime
import logging

from models.heartbeat import HeartbeatPayload
from models.trade import TradePayload
from models.event import EventPayload
from database.database import get_db
from database.models import Instance, Trade, Signal, Event, Alert

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/ea", tags=["EA Receiver"])

# ========== HEARTBEAT ENDPOINT ==========

@router.post("/heartbeat")
async def receive_heartbeat(
    payload: HeartbeatPayload,
    db: AsyncSession = Depends(get_db),
    bg_tasks: BackgroundTasks = None
):
    """
    Recebe heartbeat periódico do EA (3-5 segundos)
    
    ### Validações:
    - Valida estrutura Pydantic automaticamente
    - Salva/atualiza instância no BD
    - Dispara background tasks para broadcast WebSocket
    """
    try:
        logger.info(f"📨 Heartbeat recebido: {payload.instanceId}")
        
        # 1. Verificar se instância existe
        stmt = select(Instance).where(Instance.id == payload.instanceId)
        result = await db.execute(stmt)
        instance = result.scalar_one_or_none()
        
        if not instance:
            # Criar nova instância
            instance = Instance(
                id=payload.instanceId,
                account_number=payload.accountNumber,
                symbol=payload.symbol,
                ea_version=payload.eaVersion,
                status=payload.status,
                last_heartbeat=payload.timestamp
            )
            db.add(instance)
            logger.info(f"✨ Instância criada: {payload.instanceId}")
        else:
            # Atualizar status e timestamp
            instance.status = payload.status
            instance.last_heartbeat = payload.timestamp
        
        await db.commit()
        
        # 2. Registrar no log
        logger.debug(f"💾 Instância {payload.instanceId} atualizada")
        logger.debug(f"   Equity: R${payload.account.equity:.2f}")
        logger.debug(f"   Drawdown: {payload.daily.maxDrawdown:.2f}%")
        logger.debug(f"   Posições: {payload.positions.openCount}")
        
        # 3. Background task para broadcast (será implementado em Semana 3)
        if bg_tasks:
            bg_tasks.add_task(
                log_heartbeat_received,
                payload.instanceId,
                payload.account.equity
            )
        
        return {
            "status": "accepted",
            "timestamp": datetime.utcnow().isoformat(),
            "instanceId": payload.instanceId,
            "message": "Heartbeat processado com sucesso"
        }
        
    except Exception as e:
        logger.error(f"❌ Erro ao processar heartbeat: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))


# ========== TRADE ENDPOINT ==========

@router.post("/trade")
async def receive_trade(
    payload: TradePayload,
    db: AsyncSession = Depends(get_db),
    bg_tasks: BackgroundTasks = None
):
    """
    Recebe notificação de execução de trade
    
    ### Dados salvos:
    - Informações do trade (tipo, preço, volume)
    - Decisão e validação
    - Timestamp preciso
    """
    try:
        logger.info(f"📊 Trade recebido: {payload.trade.type} {payload.trade.symbol}")
        
        # 1. Salvar sinal (se houver informação)
        if payload.decision:
            signal = Signal(
                instance_id=payload.instanceId,
                strategy=payload.trade.strategy,
                symbol=payload.trade.symbol,
                direction=payload.decision.validationResult,
                sequence=payload.decision.sequence,
                body_size=payload.decision.bodySize,
                upper_wick=payload.decision.upperWick,
                lower_wick=payload.decision.lowerWick,
                validation_passed=(payload.decision.validationResult == "PASSED"),
                validation_details=payload.decision.validationDetails.dict(),
                signal_time=payload.timestamp
            )
            db.add(signal)
        
        # 2. Salvar trade
        trade = Trade(
            instance_id=payload.instanceId,
            trade_id=payload.tradeId,
            strategy=payload.trade.strategy,
            symbol=payload.trade.symbol,
            type=payload.trade.type,
            volume=payload.trade.volume,
            entry_price=payload.trade.entryPrice,
            stop_loss=payload.trade.stopLoss,
            take_profit=payload.trade.takeProfit,
            entry_time=payload.trade.openTime,
            magic_number=payload.trade.magicNumber,
            status="open",
            riskAmount=payload.trade.riskAmount,
            riskPercent=payload.trade.riskPercent
        )
        db.add(trade)
        
        await db.commit()
        
        logger.info(f"✅ Trade #{payload.tradeId} salvo com sucesso")
        
        return {
            "status": "accepted",
            "tradeId": payload.tradeId,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        await db.rollback()
        logger.error(f"❌ Erro ao processar trade: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))


# ========== EVENT ENDPOINT ==========

@router.post("/event")
async def receive_event(
    payload: EventPayload,
    db: AsyncSession = Depends(get_db),
    bg_tasks: BackgroundTasks = None
):
    """
    Recebe evento estruturado para logging/ML
    
    ### Tipos de evento:
    - SIGNAL_GENERATED: Sinal gerado pela estratégia
    - DAILY_RESET: Reset dos contadores diários
    - TRADE_OPENED/CLOSED: Eventos de trade
    - ERROR: Erros na execução
    """
    try:
        logger.info(f"📝 Evento recebido: {payload.eventType} ({payload.severity})")
        
        # 1. Salvar evento
        event = Event(
            instance_id=payload.instanceId,
            event_type=payload.eventType,
            severity=payload.severity,
            message=payload.message,
            event_data=payload.metadata,  # ✅ Corrigido: 'metadata' → 'event_data'
            event_time=payload.timestamp
        )
        db.add(event)
        
        # 2. Disparar alerta se severity >= WARNING
        if payload.severity in ["WARNING", "ERROR", "CRITICAL"]:
            alert = Alert(
                instance_id=payload.instanceId,
                alert_type=payload.eventType,
                severity=payload.severity,
                message=payload.message or f"{payload.eventType} - {payload.severity}",
                triggered_at=payload.timestamp
            )
            db.add(alert)
            logger.warning(f"⚠️  ALERTA: {payload.eventType} - {payload.severity}")
        
        await db.commit()
        
        # 3. Background task para notificação (Semana 3)
        if bg_tasks and payload.severity in ["WARNING", "ERROR", "CRITICAL"]:
            bg_tasks.add_task(
                notify_alert,
                payload.instanceId,
                payload.eventType,
                payload.severity
            )
        
        return {
            "status": "accepted",
            "timestamp": datetime.utcnow().isoformat(),
            "eventType": payload.eventType
        }
        
    except Exception as e:
        await db.rollback()
        logger.error(f"❌ Erro ao processar evento: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))


# ========== BACKGROUND TASKS ==========

async def log_heartbeat_received(instance_id: str, equity: float):
    """Task background: Log de heartbeat (será expandido em Semana 3)"""
    logger.debug(f"Background: Heartbeat de {instance_id} com equity R${equity:.2f}")

async def notify_alert(instance_id: str, event_type: str, severity: str):
    """Task background: Notificação de alerta (será expandido em Semana 3)"""
    logger.warning(f"Background: ALERTA enviado para {instance_id} - {event_type} ({severity})")