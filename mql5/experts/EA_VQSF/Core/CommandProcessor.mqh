#ifndef __COMMAND_PROCESSOR_MQH__
#define __COMMAND_PROCESSOR_MQH__

#include "Logger.mqh"
#include "ZeroMQCommandListener.mqh"

// Command Types 
#define CMD_START_STRATEGY          "START_STRATEGY"
#define CMD_STOP_STRATEGY           "STOP_STRATEGY"
#define CMD_CLOSE_ALL_TRADES        "CLOSE_ALL_TRADES"
#define CMD_ADJUST_PARAMETER        "ADJUST_PARAMETER"
#define CMD_SET_DAILY_LIMIT         "SET_DAILY_LIMIT"
#define CMD_PAUSE_TRADING           "PAUSE_TRADING"
#define CMD_UPDATE_TRAILING_STOP    "UPDATE_TRAILING_STOP"
#define CMD_GET_CONFIG              "GET_CONFIG"

// CCommandProcessor class
class CCommandProcessor
{
private:
   CLogger* m_logger;
   CStrategyEngine* m_engine;
   CConfigManager* m_config_manager;
   CTradeExecutor* m_executor;

public:
   //--- Constructor / Destructor
   CCommandProcessor();
   ~CCommandProcessor() {}
   
   //--- Setup
   void SetLogger(CLogger* logger) { m_logger = logger; }
   void SetEngine(CStrategyEngine* engine) { m_engine = engine; }
   void SetConfigManager(CConfigManager* config_manager) { m_config_manager = config_manager; }
   void SetExecutor(CTradeExecutor* executor) { m_executor = executor; }
   
   //--- Process Commands
   bool ProcessCommand(CommandData& cmd);
   
private:
   //--- Individual Command Handlers
   bool HandleStartStrategy(string strategy);
   bool HandleStopStrategy(string strategy);
   bool HandleCloseAllTrades(string strategy);
   bool HandleAdjustParameter(string strategy, string payload);
   bool HandleSetDailyLimit(string payload);
   bool HandlePauseTrading(string strategy, int pause_minutes);
   bool HandleUpdateTrailingStop(string strategy, double trailing_percent);
   bool HandleGetConfig(string strategy);
};

// Constructor
CCommandProcessor::CCommandProcessor()
   : m_logger(NULL),
     m_engine(NULL),
     m_config_manager(NULL),
     m_executor(NULL)
{
}

// ProcessCommand - Main dispatcher
bool CCommandProcessor::ProcessCommand(CommandData& cmd)
{
   if(m_logger == NULL)
      return false;
   
   m_logger->LogEvent("CMD_PROC", "DISPATCH", "Command: " + cmd.command_type + " | Strategy: " + cmd.strategy);
   
   // Dispatch por tipo de comando
   if(cmd.command_type == CMD_START_STRATEGY)
      return HandleStartStrategy(cmd.strategy);
   
   else if(cmd.command_type == CMD_STOP_STRATEGY)
      return HandleStopStrategy(cmd.strategy);
   
   else if(cmd.command_type == CMD_CLOSE_ALL_TRADES)
      return HandleCloseAllTrades(cmd.strategy);
   
   else if(cmd.command_type == CMD_ADJUST_PARAMETER)
      return HandleAdjustParameter(cmd.strategy, cmd.payload);
   
   else if(cmd.command_type == CMD_SET_DAILY_LIMIT)
      return HandleSetDailyLimit(cmd.payload);
   
   else if(cmd.command_type == CMD_PAUSE_TRADING)
      return HandlePauseTrading(cmd.strategy, 30);  // Default 30 min
   
   else if(cmd.command_type == CMD_UPDATE_TRAILING_STOP)
      return HandleUpdateTrailingStop(cmd.strategy, 1.5);  // Default 1.5%
   
   else if(cmd.command_type == CMD_GET_CONFIG)
      return HandleGetConfig(cmd.strategy);
   
   else
   {
      m_logger->LogEvent("CMD_PROC", "ERROR", "Unknown command: " + cmd.command_type);
      return false;
   }
}

// Handler: START_STRATEGY
bool CCommandProcessor::HandleStartStrategy(string strategy)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "START_STRATEGY", "Strategy: " + strategy);
   
   // TODO: Implementar lógica de start
   // Exemplo: m_engine.EnableStrategy(strategy);
   
   return true;
}

// Handler: STOP_STRATEGY
bool CCommandProcessor::HandleStopStrategy(string strategy)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "STOP_STRATEGY", "Strategy: " + strategy);
   
   // TODO: Implementar lógica de stop
   // Exemplo: m_engine.DisableStrategy(strategy);
   
   return true;
}

// Handler: CLOSE_ALL_TRADES
bool CCommandProcessor::HandleCloseAllTrades(string strategy)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "CLOSE_ALL_TRADES", "Strategy: " + strategy);
   
   if(m_executor == NULL)
      return false;
   
   // TODO: Implementar close all
   // Exemplo: m_executor.CloseAllTrades(logger);
   
   return true;
}

// Handler: ADJUST_PARAMETER
bool CCommandProcessor::HandleAdjustParameter(string strategy, string payload)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "ADJUST_PARAMETER", "Strategy: " + strategy + " | Payload: " + payload);
   
   // TODO: Parse JSON e ajustar parâmetro
   // Exemplo: m_config_manager.SetParameter(strategy, param_name, param_value);
   
   return true;
}

// Handler: SET_DAILY_LIMIT
bool CCommandProcessor::HandleSetDailyLimit(string payload)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "SET_DAILY_LIMIT", "Payload: " + payload);
   
   // TODO: Parse JSON e atualizar daily limits
   
   return true;
}

// Handler: PAUSE_TRADING
bool CCommandProcessor::HandlePauseTrading(string strategy, int pause_minutes)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "PAUSE_TRADING", "Strategy: " + strategy + " | Duration: " + IntegerToString(pause_minutes) + " min");
   
   // TODO: Pausar trading por X minutos
   
   return true;
}

// Handler: UPDATE_TRAILING_STOP
bool CCommandProcessor::HandleUpdateTrailingStop(string strategy, double trailing_percent)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "UPDATE_TRAILING_STOP", "Strategy: " + strategy + " | Percent: " + DoubleToString(trailing_percent, 2));
   
   // TODO: Atualizar trailing stop
   
   return true;
}

// Handler: GET_CONFIG
bool CCommandProcessor::HandleGetConfig(string strategy)
{
   if(m_logger) m_logger->LogEvent("CMD_PROC", "GET_CONFIG", "Strategy: " + strategy);
   
   // TODO: Retornar configuração atual da estratégia
   
   return true;
}

#endif