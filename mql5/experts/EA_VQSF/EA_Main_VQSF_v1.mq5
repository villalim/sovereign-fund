#property copyright "Copyright 2026, Evilazio Lima"
#property link      "https://www.mql5.com"
#property version   "5.02"
#property strict

#include "Core/Types.mqh"
#include "Core/Utils.mqh"
#include "Core/Logger.mqh"
#include "Core/BaseConfig.mqh"
#include "Core/StrategyHelper.mqh"
#include "Core/NewsFilter.mqh"
#include "Core/JSONParser.mqh"
#include "Core/DailyLimits.mqh"
#include "Core/HeartbeatHTTP.mqh"
#include "Core/BridgeHTTP.mqh"
#include "Core/PositionManager.mqh"
#include "Core/OrderManager.mqh"
#include "Core/RiskManager.mqh"
#include "Core/CommandListener.mqh"
#include "Config/Config_3BullGoDown.mqh"
#include "Config/Config_3BearGoDown.mqh"
#include "Config/Config_2Bear2BullGoUP.mqh"
#include "Core/ConfigManager.mqh"
#include "Strategies/Strategy_3BullGoDown.mqh"
#include "Strategies/Strategy_3BearGoDown.mqh"
#include "Strategies/Strategy_2Bear2BullGoUP.mqh"
#include "Engine/StrategyEngine.mqh"
#include "Execution/TradeExecutor.mqh"

// ================= GLOBAL INSTANCES =================

CLogger logger;
CStrategyEngine engine;
CTradeExecutor executor;
CConfigManager configManager;
CHeartbeatHTTP heartbeat;
CBridgeHTTP bridge;
CPositionManager positionManager;
COrderManager orderManager;
CRiskManager riskManager;
CTrailingStopLogger tsLogger;
CCommandListener commandListener;

long accountNumber;

CStrategy_3BullGoDown strategy3BullGoDown;
CStrategy_3BearGoDown strategy3BearGoDown;
CStrategy_2Bear2BullGoUP strategy2Bear2BullGoUp;

// ================= INPUT PARAMETERS =================

input group "General Configuration"
input bool InpLoadConfigFromFile = true;
input string InpConfigFilePath = "strategies_config.json";
input bool InpEnableAIAdjustments = true;
input bool InpAutoSyncToFile = true;

input group "HTTP Bridge Configuration"
input bool InpEnableHTTPBridge = true;
input string InpServerURL = "http://localhost:5000";
input bool InpEnableHeartbeat = true;
input int InpHeartbeatIntervalSeconds = 5;

input group "Risk Management"
input double InpInitialDeposit = 10000.0;
input int    InpLotCalculationType = 0;
input double InpMaxRiskPerTrade = 2.0;
input double InpMaxExposure = 10000.0;
input int    InpMaxPositionsCount = 10;
input double InpMaxDailyLoss = 300.0;

input group "Daily Limits"
input int InpDailyCloseHour = 16;
input int InpDailyCloseMinute = 0;
input double InpMaxDailyProfit = 4000.0;

input group "3BullGoDown Strategy"
input bool Inp3BullGoDown_Enabled = true;
input int Inp3BullGoDown_StartHour = 3;
input int Inp3BullGoDown_StartMinute = 0;
input int Inp3BullGoDown_EndHour = 22;
input int Inp3BullGoDown_EndMinute = 0;
input int Inp3BullGoDown_NewsFilterPauseMinutes = 0;
input int Inp3BullGoDown_NewsFilterCloseMinutes = 0;
input int Inp3BullGoDown_MagicNumber = 10003;
input int    Inp3BullGoDown_LotCalculationType = 0;
input double Inp3BullGoDown_InitialDeposit = 10000.0;
input double Inp3BullGoDown_MaxRiskPerTrade = 1.0;
input double Inp3BullGoDown_LotSize = 0.16;
input int Inp3BullGoDown_StopLoss = 2000;
input int Inp3BullGoDown_MinSequence = 3;
input double Inp3BullGoDown_MinCandleSize = 300;
input double Inp3BullGoDown_MaxCandleSize = 5000;
input double Inp3BullGoDown_MinTakeProfit = 1600;
input double Inp3BullGoDown_MaxTakeProfit = 10000;
input double Inp3BullGoDown_LongSequenceMultiplier = 2.0;
input bool Inp3BullGoDown_EnableTrailingStop = true;
input double Inp3BullGoDown_TrailingStopActivationPercent = 50.0;

input group "3BearGoDown Strategy"
input bool Inp3BearGoDown_Enabled = false;
input int Inp3BearGoDown_StartHour = 1;
input int Inp3BearGoDown_StartMinute = 0;
input int Inp3BearGoDown_EndHour = 22;
input int Inp3BearGoDown_EndMinute = 0;
input int Inp3BearGoDown_NewsFilterPauseMinutes = 0;
input int Inp3BearGoDown_NewsFilterCloseMinutes = 0;
input int Inp3BearGoDown_MagicNumber = 10001;
input int    Inp3BearGoDown_LotCalculationType = 0;
input double Inp3BearGoDown_InitialDeposit = 10000.0;
input double Inp3BearGoDown_MaxRiskPerTrade = 1.0;
input double Inp3BearGoDown_LotSize = 0.16;
input int Inp3BearGoDown_StopLoss = 2000;
input int Inp3BearGoDown_MinSequence = 3;
input double Inp3BearGoDown_MinCandleSize = 300;
input double Inp3BearGoDown_MaxCandleSize = 5000;
input double Inp3BearGoDown_MinTakeProfit = 1600;
input double Inp3BearGoDown_MaxTakeProfit = 10000;
input double Inp3BearGoDown_LongSequenceMultiplier = 2.0;
input bool Inp3BearGoDown_EnableTrailingStop = true;
input double Inp3BearGoDown_TrailingStopActivationPercent = 50.0;

input group "2Bear2BullGoUp Strategy"
input bool Inp2Bear2BullGoUp_Enabled = false;
input int Inp2Bear2BullGoUp_StartHour = 3;
input int Inp2Bear2BullGoUp_StartMinute = 0;
input int Inp2Bear2BullGoUp_EndHour = 22;
input int Inp2Bear2BullGoUp_EndMinute = 0;
input int Inp2Bear2BullGoUp_NewsFilterPauseMinutes = 0;
input int Inp2Bear2BullGoUp_NewsFilterCloseMinutes = 0;
input int Inp2Bear2BullGoUp_MagicNumber = 10002;
input int    Inp2Bear2BullGoUp_LotCalculationType = 0;
input double Inp2Bear2BullGoUp_InitialDeposit = 10000.0;
input double Inp2Bear2BullGoUp_MaxRiskPerTrade = 1.0;
input double Inp2Bear2BullGoUp_LotSize = 0.1;
input int Inp2Bear2BullGoUp_StopLoss = 2000;
input int Inp2Bear2BullGoUp_MinSequence = 4;
input double Inp2Bear2BullGoUp_MinCandleSize = 50;
input double Inp2Bear2BullGoUp_MaxCandleSize = 5000;
input double Inp2Bear2BullGoUp_MinTakeProfit = 1600;
input double Inp2Bear2BullGoUp_MaxTakeProfit = 10000;
input double Inp2Bear2BullGoUp_LongSequenceMultiplier = 2.0;
input bool Inp2Bear2BullGoUp_EnableTrailingStop = true;
input double Inp2Bear2BullGoUp_TrailingStopActivationPercent = 50.0;

// ================= INITIALIZATION =================

int OnInit()
{
   logger.Init();
   logger.LogDebug("EA", "INFO", "Logger initialized successfully");
   logger.LogEvent("EA", "INIT", "EA_Main_VQSF v5.02 initializing...");

   accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
   logger.LogEvent("EA", "INIT", "Account: " + IntegerToString(accountNumber));

   configManager.SetLogger(&logger);
   configManager.SetConfigFilePath(InpConfigFilePath);
   configManager.SetAutoSync(InpAutoSyncToFile);

   if(InpLoadConfigFromFile)
   {
      if(!configManager.LoadFromFile())
      {
         logger.LogEvent("EA", "WARNING", "Could not load config from file. Using input parameters.");
      }
   }

   configManager.SyncInputsToConfigs(
      Inp3BullGoDown_Enabled, Inp3BullGoDown_StartHour, Inp3BullGoDown_StartMinute,
      Inp3BullGoDown_EndHour, Inp3BullGoDown_EndMinute, Inp3BullGoDown_NewsFilterPauseMinutes,
      Inp3BullGoDown_NewsFilterCloseMinutes, Inp3BullGoDown_MagicNumber, Inp3BullGoDown_LotSize,
      Inp3BullGoDown_StopLoss, Inp3BullGoDown_MinSequence, Inp3BullGoDown_MinCandleSize,
      Inp3BullGoDown_MaxCandleSize, Inp3BullGoDown_MinTakeProfit, Inp3BullGoDown_MaxTakeProfit,
      Inp3BullGoDown_LongSequenceMultiplier, Inp3BullGoDown_EnableTrailingStop,
      Inp3BullGoDown_TrailingStopActivationPercent,
      Inp3BullGoDown_LotCalculationType, Inp3BullGoDown_InitialDeposit, Inp3BullGoDown_MaxRiskPerTrade,
      Inp3BearGoDown_Enabled, Inp3BearGoDown_StartHour, Inp3BearGoDown_StartMinute,
      Inp3BearGoDown_EndHour, Inp3BearGoDown_EndMinute, Inp3BearGoDown_NewsFilterPauseMinutes,
      Inp3BearGoDown_NewsFilterCloseMinutes, Inp3BearGoDown_MagicNumber, Inp3BearGoDown_LotSize,
      Inp3BearGoDown_StopLoss, Inp3BearGoDown_MinSequence, Inp3BearGoDown_MinCandleSize,
      Inp3BearGoDown_MaxCandleSize, Inp3BearGoDown_MinTakeProfit, Inp3BearGoDown_MaxTakeProfit,
      Inp3BearGoDown_LongSequenceMultiplier, Inp3BearGoDown_EnableTrailingStop,
      Inp3BearGoDown_TrailingStopActivationPercent,
      Inp3BearGoDown_LotCalculationType, Inp3BearGoDown_InitialDeposit, Inp3BearGoDown_MaxRiskPerTrade,
      Inp2Bear2BullGoUp_Enabled, Inp2Bear2BullGoUp_StartHour, Inp2Bear2BullGoUp_StartMinute,
      Inp2Bear2BullGoUp_EndHour, Inp2Bear2BullGoUp_EndMinute, Inp2Bear2BullGoUp_NewsFilterPauseMinutes,
      Inp2Bear2BullGoUp_NewsFilterCloseMinutes, Inp2Bear2BullGoUp_MagicNumber, Inp2Bear2BullGoUp_LotSize,
      Inp2Bear2BullGoUp_StopLoss, Inp2Bear2BullGoUp_MinSequence, Inp2Bear2BullGoUp_MinCandleSize,
      Inp2Bear2BullGoUp_MaxCandleSize, Inp2Bear2BullGoUp_MinTakeProfit, Inp2Bear2BullGoUp_MaxTakeProfit,
      Inp2Bear2BullGoUp_LongSequenceMultiplier, Inp2Bear2BullGoUp_EnableTrailingStop,
      Inp2Bear2BullGoUp_TrailingStopActivationPercent,
      Inp2Bear2BullGoUp_LotCalculationType, Inp2Bear2BullGoUp_InitialDeposit, Inp2Bear2BullGoUp_MaxRiskPerTrade
   );

   engine.SetLogger(&logger);
   engine.SetDailyLimits(InpDailyCloseHour, InpDailyCloseMinute, InpMaxDailyLoss, InpMaxDailyProfit);

   logger.LogEvent("EA", "INIT", "Daily Limits - Close: " + IntegerToString(InpDailyCloseHour) + ":" +
                            IntegerToString(InpDailyCloseMinute) + " | Max Loss: " +
                            DoubleToString(InpMaxDailyLoss, 2) + " | Max Profit: " +
                            DoubleToString(InpMaxDailyProfit, 2));

   if(!engine.AddStrategy(&strategy3BullGoDown, configManager.GetConfig3BullGoDown()))
   {
      logger.LogEvent("EA", "ERROR", "Failed to add 3BullGoDown strategy");
      return INIT_FAILED;
   }

   if(!engine.AddStrategy(&strategy3BearGoDown, configManager.GetConfig3BearGoDown()))
   {
      logger.LogEvent("EA", "ERROR", "Failed to add 3BearGoDown strategy");
      return INIT_FAILED;
   }

   if(!engine.AddStrategy(&strategy2Bear2BullGoUp, configManager.GetConfig2Bear2BullGoUp()))
   {
      logger.LogEvent("EA", "ERROR", "Failed to add 2Bear2BullGoUp strategy");
      return INIT_FAILED;
   }

   executor.SetLogger(&logger);
   executor.SetTrailingStopLogger(&tsLogger);
   executor.SetRiskManager(&riskManager);

   logger.LogEvent("EA", "INIT", "RiskManager assigned to TradeExecutor");

   InitializeHTTPBridge();
   InitializeHeartbeat();
   InitializeManagers();

   logger.LogEvent("EA", "INIT", "EA initialized successfully with " + IntegerToString(engine.GetStrategyCount()) +
                            " strategies, HTTP Bridge, and Position/Order/Risk Management");

   return INIT_SUCCEEDED;
}

void InitializeHTTPBridge()
{
   if(!InpEnableHTTPBridge)
   {
      logger.LogEvent("EA", "HTTP_BRIDGE", "HTTP Bridge disabled");
      return;
   }

   bridge.SetLogger(&logger);
   bridge.SetServerUrl(InpServerURL);
   bridge.SetMaxRetries(3);
   bridge.SetRetryDelay(1000);

   if(bridge.Connect())
   {
      logger.LogEvent("EA", "HTTP_BRIDGE", "HTTP Bridge connected to: " + InpServerURL);
   }
   else
   {
      logger.LogEvent("EA", "HTTP_BRIDGE", "HTTP Bridge failed to connect - will retry");
   }
}

void InitializeHeartbeat()
{
   if(!InpEnableHeartbeat)
   {
      logger.LogEvent("EA", "HEARTBEAT", "Heartbeat disabled");
      return;
   }

   heartbeat.SetLogger(&logger);
   heartbeat.SetServerUrl(InpServerURL + "/heartbeat");
   heartbeat.SetHeartbeatInterval(InpHeartbeatIntervalSeconds);
   heartbeat.SetInstanceId(_Symbol + "_" + IntegerToString(accountNumber));
   heartbeat.SetAccountNumber(IntegerToString(accountNumber));
   heartbeat.SetStrategyList("3BullGoDown,3BearGoDown,2Bear2BullGoUp");
   heartbeat.Enable();

   logger.LogEvent("EA", "HEARTBEAT", "Heartbeat enabled - Interval: " + IntegerToString(InpHeartbeatIntervalSeconds) + "s");
}

void InitializeManagers()
{
   positionManager.SetLogger(&logger);
   orderManager.SetLogger(&logger);
   riskManager.SetLogger(&logger);

   riskManager.SetGlobalInitialDeposit(InpInitialDeposit);
   riskManager.SetGlobalLotCalculationType(InpLotCalculationType);
   riskManager.SetGlobalMaxRiskPerTrade(InpMaxRiskPerTrade);
   riskManager.SetMaxExposure(InpMaxExposure);
   riskManager.SetMaxPositionsCount(InpMaxPositionsCount);
   riskManager.SetDailyLossLimit(InpMaxDailyLoss);
   riskManager.InitializeStartingEquity();

   riskManager.SetStrategyLotConfiguration("3BullGoDown", Inp3BullGoDown_LotCalculationType,
                                           Inp3BullGoDown_InitialDeposit, Inp3BullGoDown_MaxRiskPerTrade);
   riskManager.SetStrategyLotConfiguration("3BearGoDown", Inp3BearGoDown_LotCalculationType,
                                           Inp3BearGoDown_InitialDeposit, Inp3BearGoDown_MaxRiskPerTrade);
   riskManager.SetStrategyLotConfiguration("2Bear2BullGoUp", Inp2Bear2BullGoUp_LotCalculationType,
                                           Inp2Bear2BullGoUp_InitialDeposit, Inp2Bear2BullGoUp_MaxRiskPerTrade);

   commandListener.SetLogger(&logger);
   commandListener.SetServerUrl(InpServerURL + "/commands");
   commandListener.SetPollInterval(5000);
   commandListener.Start();

   logger.LogEvent("EA", "MANAGERS", "CommandListener initialized and started");
   logger.LogEvent("EA", "MANAGERS", "Position, Order, and Risk managers initialized");
   logger.LogEvent("EA", "STRATEGY_CONFIGS", "Strategy-specific lot configurations loaded");
}

// ================= COMMAND PROCESSING =================

void ProcessCommands()
{
   CommandData cmd;

   if(!commandListener.CheckForCommand(cmd))
      return;

   logger.LogEvent("EA", "COMMAND", "Processing command type: " + IntegerToString((int)cmd.type));

   bool success = false;
   string resultMsg = "";

   switch(cmd.type)
   {
      case CMD_START_STRATEGY:
         success = ProcessCommand_StartStrategy(cmd);
         resultMsg = "Strategy " + cmd.strategy + (success ? " started" : " not found");
         break;

      case CMD_STOP_STRATEGY:
         success = ProcessCommand_StopStrategy(cmd);
         resultMsg = "Strategy " + cmd.strategy + (success ? " stopped" : " not found");
         break;

      case CMD_CLOSE_ALL_TRADES:
         success = ProcessCommand_CloseAllTrades(cmd);
         resultMsg = "All trades closed for " + cmd.strategy;
         break;

      case CMD_ADJUST_PARAMETER:
         success = ProcessCommand_AdjustParameter(cmd);
         resultMsg = "Parameter " + cmd.paramName + " adjusted to " + DoubleToString(cmd.paramValue, 2);
         break;

      case CMD_SET_DAILY_LIMIT:
         success = ProcessCommand_SetDailyLimit(cmd);
         resultMsg = "Daily limits updated";
         break;

      case CMD_PAUSE_TRADING:
         success = ProcessCommand_PauseTrading(cmd);
         resultMsg = "Trading paused for " + IntegerToString(cmd.pauseMinutes) + " minutes";
         break;

      case CMD_UPDATE_TRAILING_STOP:
         success = ProcessCommand_UpdateTrailingStop(cmd);
         resultMsg = "Trailing stop updated to " + DoubleToString(cmd.trailingPercent, 2) + "%";
         break;

      case CMD_GET_CONFIG:
         success = ProcessCommand_GetConfig(cmd);
         resultMsg = "Configuration sent";
         break;

      default:
         logger.LogEvent("EA", "COMMAND", "Unknown command type");
         return;
   }

   if(InpEnableHTTPBridge)
      bridge.SendCommandResponse(cmd.commandId, success ? "EXECUTED" : "FAILED", resultMsg);
}

// --- COMANDO 1: START_STRATEGY ---
bool ProcessCommand_StartStrategy(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_START", "Starting strategy: " + cmd.strategy);

   CBaseConfig* config = NULL;

   if(cmd.strategy == "3BullGoDown")
      config = configManager.GetConfig3BullGoDown();
   else if(cmd.strategy == "3BearGoDown")
      config = configManager.GetConfig3BearGoDown();
   else if(cmd.strategy == "2Bear2BullGoUp")
      config = configManager.GetConfig2Bear2BullGoUp();

   if(config != NULL)
   {
      config.Enabled = true;
      logger.LogEvent("EA", "CMD_START", cmd.strategy + " strategy enabled");
      return true;
   }

   logger.LogEvent("EA", "CMD_START", "Strategy not found: " + cmd.strategy);
   return false;
}

// --- COMANDO 2: STOP_STRATEGY ---
bool ProcessCommand_StopStrategy(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_STOP", "Stopping strategy: " + cmd.strategy);

   CBaseConfig* config = NULL;

   if(cmd.strategy == "3BullGoDown")
      config = configManager.GetConfig3BullGoDown();
   else if(cmd.strategy == "3BearGoDown")
      config = configManager.GetConfig3BearGoDown();
   else if(cmd.strategy == "2Bear2BullGoUp")
      config = configManager.GetConfig2Bear2BullGoUp();

   if(config != NULL)
   {
      config.Enabled = false;
      logger.LogEvent("EA", "CMD_STOP", cmd.strategy + " strategy disabled");
      return true;
   }

   logger.LogEvent("EA", "CMD_STOP", "Strategy not found: " + cmd.strategy);
   return false;
}

// --- COMANDO 3: CLOSE_ALL_TRADES ---
bool ProcessCommand_CloseAllTrades(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_CLOSE_ALL", "Closing all trades for strategy: " + cmd.strategy);
   executor.CloseAllTrades(logger);
   return true;
}

// --- COMANDO 4: ADJUST_PARAMETER ---
// --- COMANDO 4: ADJUST_PARAMETER ---
bool ProcessCommand_AdjustParameter(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_ADJUST",
      "Adjusting " + cmd.strategy + "." + cmd.paramName + " = " + DoubleToString(cmd.paramValue, 2));

   CBaseConfig* config = NULL;

   if(cmd.strategy == "3BullGoDown")
      config = configManager.GetConfig3BullGoDown();
   else if(cmd.strategy == "3BearGoDown")
      config = configManager.GetConfig3BearGoDown();
   else if(cmd.strategy == "2Bear2BullGoUp")
      config = configManager.GetConfig2Bear2BullGoUp();

   if(config == NULL)
   {
      logger.LogEvent("EA", "CMD_ADJUST", "Strategy not found: " + cmd.strategy);
      return false;
   }

   // ✅ Ajustar parâmetros diretamente
   if(cmd.paramName == "LotSize")
      config.LotSize = cmd.paramValue;
   else if(cmd.paramName == "StopLossPoints")
      config.StopLossPoints = (int)cmd.paramValue;
   else if(cmd.paramName == "MinSequence")
      config.MinSequence = (int)cmd.paramValue;
   else if(cmd.paramName == "MinCandleSize")
      config.MinCandleSize = cmd.paramValue;
   else if(cmd.paramName == "MaxCandleSize")
      config.MaxCandleSize = cmd.paramValue;
   else if(cmd.paramName == "MinTakeProfit")
      config.MinTakeProfit = cmd.paramValue;
   else if(cmd.paramName == "MaxTakeProfit")
      config.MaxTakeProfit = cmd.paramValue;
   else if(cmd.paramName == "LongSequenceMultiplier")
      config.LongSequenceMultiplier = cmd.paramValue;
   else if(cmd.paramName == "TrailingStopActivationPercent")
      config.TrailingStopActivationPercent = cmd.paramValue;
   else
   {
      logger.LogEvent("EA", "CMD_ADJUST", "Parameter not found: " + cmd.paramName);
      return false;
   }

   // ✅ CORRIGIDO: SaveToFile() ao invés de SyncToFile()
   if(InpAutoSyncToFile)
      configManager.SaveToFile();

   return true;
}

// --- COMANDO 5: SET_DAILY_LIMIT ---
bool ProcessCommand_SetDailyLimit(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_DAILY_LIMIT",
      "Setting daily limits - Profit: " + DoubleToString(cmd.dailyProfitLimit, 2) +
      " | Loss: " + DoubleToString(cmd.dailyLossLimit, 2));

   riskManager.SetDailyLossLimit(cmd.dailyLossLimit);
   return true;
}

// --- COMANDO 6: PAUSE_TRADING ---
bool ProcessCommand_PauseTrading(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_PAUSE",
      "Pausing trading for " + IntegerToString(cmd.pauseMinutes) + " minutes");

   // TODO: Implementar lógica de pausa
   return true;
}

// --- COMANDO 7: UPDATE_TRAILING_STOP ---
// --- COMANDO 7: UPDATE_TRAILING_STOP ---
bool ProcessCommand_UpdateTrailingStop(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_TRAILING_STOP",
      "Updating trailing stop to " + DoubleToString(cmd.trailingPercent, 2) + "%");

   CBaseConfig* config = NULL;

   if(cmd.strategy == "3BullGoDown")
      config = configManager.GetConfig3BullGoDown();
   else if(cmd.strategy == "3BearGoDown")
      config = configManager.GetConfig3BearGoDown();
   else if(cmd.strategy == "2Bear2BullGoUp")
      config = configManager.GetConfig2Bear2BullGoUp();

   if(config == NULL)
   {
      logger.LogEvent("EA", "CMD_TRAILING_STOP", "Strategy not found: " + cmd.strategy);
      return false;
   }

   config.TrailingStopActivationPercent = cmd.trailingPercent;

   // ✅ CORRIGIDO: SaveToFile() ao invés de SyncToFile()
   if(InpAutoSyncToFile)
      configManager.SaveToFile();

   return true;
}

// --- COMANDO 8: GET_CONFIG ---
bool ProcessCommand_GetConfig(CommandData &cmd)
{
   logger.LogEvent("EA", "CMD_GET_CONFIG", "Sending configuration for: " + cmd.strategy);

   // TODO: Implementar envio de configuração via HTTP
   return true;
}

// ================= DEINITIALIZATION =================

void OnDeinit(const int reason)
{
   logger.LogEvent("EA", "DEINIT", "EA shutting down. Reason: " + IntegerToString(reason));

   if(InpEnableHeartbeat)
      heartbeat.Disable();

   if(InpEnableHTTPBridge)
      bridge.Disconnect();

   commandListener.Stop();

   riskManager.LogRiskReport();

   logger.LogEvent("EA", "INFO", "Final metrics saved to log files");
}

// ================= MAIN TICK =================

void OnTick()
{
   if(!IsNewCandle(PERIOD_M15))
      return;

   ProcessHeartbeat();
   ProcessCommands();
   ProcessPositionMonitoring();
   ProcessOrderMonitoring();
   ProcessRiskValidation();

   executor.ProcessTrades(logger);
   executor.CloseTradesDueToNews(engine.newsFilter, logger);
   engine.ProcessAll(executor, logger);

   ProcessMetrics();

   static int tickCount = 0;
   tickCount++;

   if(tickCount >= 100)
   {
      logger.LogEvent("EA", "PERIODIC_METRICS", "Summary: " + IntegerToString(tickCount) + " ticks processed");
      positionManager.LogPositionSummary();
      orderManager.LogOrderSummary();
      tickCount = 0;
   }
}

void ProcessHeartbeat()
{
   if(!InpEnableHeartbeat)
      return;

   if(heartbeat.ShouldSendHeartbeat())
   {
      heartbeat.SendHeartbeat();
   }
}

void ProcessPositionMonitoring()
{
   int openPositions = positionManager.GetOpenPositionCount();

   if(openPositions > 0)
   {
      logger.LogDebug("EA", "POSITIONS", "Total open positions: " + IntegerToString(openPositions));

      for(int i = 0; i < openPositions; i++)
      {
         PositionInfo info = positionManager.GetPosition(i);
         if(info.ticket > 0)
         {
            logger.LogDebug("EA", "POSITION_DETAIL", positionManager.GetPositionDetails(i));
         }
      }
   }
}

void ProcessOrderMonitoring()
{
   int pendingOrders = orderManager.GetPendingOrderCount();

   if(pendingOrders > 0)
   {
      logger.LogDebug("EA", "ORDERS", "Total pending orders: " + IntegerToString(pendingOrders));
      orderManager.LogOrderSummary();
   }
}

void ProcessRiskValidation()
{
   riskManager.CheckAndResetDailyLimits();

   if(riskManager.IsDailyLossExceeded())
   {
      logger.LogEvent("EA", "RISK_ALERT", "Daily loss limit exceeded - Closing all trades");
      executor.CloseAllTrades(logger);
      return;
   }

   if(riskManager.IsDailyProfitExceeded())
   {
      logger.LogEvent("EA", "PROFIT_ALERT", "Daily profit target reached - Closing all trades");
      executor.CloseAllTrades(logger);
      return;
   }

   double drawdownPercent = riskManager.GetDrawdownPercent();
   if(drawdownPercent > 0)
   {
      logger.LogDebug("EA", "RISK_MONITOR",
         "Drawdown: " + DoubleToString(drawdownPercent, 2) + "% | " +
         "Daily Loss: " + DoubleToString(riskManager.GetDailyLossAmount(), 2) + " | " +
         "Daily Profit: " + DoubleToString(riskManager.GetDailyProfitAmount(), 2) + " | " +
         "Exposure: " + DoubleToString(riskManager.GetTotalExposure(), 2));
   }
}

void ProcessMetrics()
{
   if(!InpEnableHTTPBridge || !bridge.IsConnected())
      return;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   int openTrades = PositionsTotal();
   double dailyPnL = equity - balance;

   bridge.SendMetrics("SYSTEM", equity, balance, openTrades, dailyPnL);
}

void OnTimer()
{
}