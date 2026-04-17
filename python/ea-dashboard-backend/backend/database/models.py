from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class HeartbeatLog(Base):
    __tablename__ = 'heartbeat_logs'
    
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime)
    instance_id = Column(String)
    balance = Column(Float)
    equity = Column(Float)
    positions = Column(String)  # Pode ser JSON ou texto
    strategies = Column(String)  # Pode ser JSON ou texto

class Command(Base):
    __tablename__ = 'commands'
    
    id = Column(Integer, primary_key=True)
    command_id = Column(String, unique=True)
    type = Column(String)
    strategy = Column(String)
    status = Column(String)
    created_at = Column(DateTime)
    executed_at = Column(DateTime, nullable=True)

class CommandResponse(Base):
    __tablename__ = 'command_responses'
    
    id = Column(Integer, primary_key=True)
    response_id = Column(String, unique=True)
    command_id = Column(String, ForeignKey('commands.command_id'))
    status = Column(String)
    result = Column(String)
    timestamp = Column(DateTime)