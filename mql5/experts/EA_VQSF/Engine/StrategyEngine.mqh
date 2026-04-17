#ifndef __STRATEGY_ENGINE_MQH__
#define __STRATEGY_ENGINE_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
#include "../Core/BaseConfig.mqh"
#include "../Core/NewsFilter.mqh"
#include "../Core/DailyLimits.mqh"
#include "../Execution/TradeExecutor.mqh"

// Configs
#include "../Config/Config_3BullGoDown.mqh"
#include "../Config/Config_2Bear2BullGoUP.mqh"
#include "../Config/Config_3BearGoDown.mqh"

// Estratégias
#include "../Strategies/Strategy_3BullGoDown.mqh"
#include "../Strategies/Strategy_2Bear2BullGoUP.mqh"
#include "../Strategies/Strategy_3BearGoDown.mqh"

// ================= STRATEGY ENGINE CLASS =================
class CStrategyEngine
{
private:
   CBaseStrategy* strategies[10];
   CBaseConfig* configs[10];
   int strategyCount;
   CLogger* logger;

public:
   CNewsFilter newsFilter;
   CDailyLimits dailyLimits;

   // ================= CONSTRUCTOR =================
   CStrategyEngine()
   {
      strategyCount = 0;
      logger = NULL;
   }

   // ================= SET LOGGER =================
   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   // ================= ADD STRATEGY =================
   bool AddStrategy(CBaseStrategy* strategy, CBaseConfig* config)
   {
      if(strategyCount >= 10)
      {
         if(logger) logger.LogEvent("ENGINE", "ERROR", "Max strategies reached");
         return false;
      }

      if(strategy == NULL || config == NULL)
      {
         if(logger) logger.LogEvent("ENGINE", "ERROR", "Invalid strategy or config");
         return false;
      }

      // Validar config
      if(!config.Validate())
      {
         if(logger) logger.LogEvent("ENGINE", "ERROR", "Invalid config for " + strategy.GetName());
         return false;
      }

      // Configurar estratégia
      strategy.SetConfig(config);
      strategy.SetLogger(logger);

      strategies[strategyCount] = strategy;
      configs[strategyCount] = config;
      strategyCount++;

      if(logger) logger.LogEvent("ENGINE", "ADD_STRATEGY", "Added: " + strategy.GetName());

      return true;
   }

   // ================= PROCESS ALL =================
   void ProcessAll(CTradeExecutor &exec, CLogger &log)
   {
      // Obter hora e minuto atuais
      datetime now = TimeCurrent();
      MqlDateTime timeStruct;
      TimeToStruct(now, timeStruct);
      int currentHour = timeStruct.hour;
      int currentMinute = timeStruct.min;

      // ================= INICIALIZAR SALDO DIÁRIO =================
      double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE) + AccountInfoDouble(ACCOUNT_CREDIT);
      dailyLimits.InitializeDailyBalance(currentBalance);

      // ================= VERIFICAR HORÁRIO DE FECHAMENTO DIÁRIO =================
      if(dailyLimits.ShouldCloseForDay())
      {
         exec.CloseAllTrades(log);
         if(logger)
            logger.LogEvent("DAILY_LIMITS", "CLOSE_TIME", "Daily close time reached - All trades closed");
         return;
      }

      // ================= VERIFICAR LIMITES DE PERDA/GANHO DIÁRIO =================
      if(dailyLimits.IsDailyLossLimitReached(currentBalance))
      {
         exec.CloseAllTrades(log);
         if(logger)
            logger.LogEvent("DAILY_LIMITS", "LOSS_LIMIT", 
               "Daily loss limit reached: " + DoubleToString(dailyLimits.GetDailyPnL(currentBalance), 2));
         return;
      }

      if(dailyLimits.IsDailyProfitLimitReached(currentBalance))
      {
         exec.CloseAllTrades(log);
         if(logger)
            logger.LogEvent("DAILY_LIMITS", "PROFIT_LIMIT", 
               "Daily profit limit reached: " + DoubleToString(dailyLimits.GetDailyPnL(currentBalance), 2));
         return;
      }

      // ================= PROCESSAR CADA ESTRATÉGIA =================
      for(int i = 0; i < strategyCount; i++)
      {
         if(strategies[i] == NULL || configs[i] == NULL)
            continue;

         string strategyName = strategies[i].GetName();

         // ================= VERIFICAR SE ESTRATÉGIA ESTÁ HABILITADA =================
         if(!strategies[i].IsStrategyEnabled())
         {
            if(logger)
            {
               logger.LogEvent(strategyName, "SKIP", "Strategy is disabled");
               logger.LogDebug(strategyName, "TRACE", "Strategy disabled - skipping");
            }
            continue;
         }

         // ✅ NOVO: VERIFICAR FILTRO DE HORÁRIO DE OPERAÇÃO =================
         if(!configs[i].IsWithinTradingHours(currentHour, currentMinute))
         {
            if(logger)
            {
               logger.LogEvent(strategyName, "SKIP", 
                  "Outside trading hours (" + IntegerToString(currentHour) + ":" + 
                  IntegerToString(currentMinute) + ")");
               
               logger.LogDebug(strategyName, "TRACE", 
                  "Outside trading hours (" + IntegerToString(currentHour) + ":" + 
                  IntegerToString(currentMinute) + ") - allowed: " + 
                  IntegerToString(configs[i].StartHour) + ":" + 
                  IntegerToString(configs[i].StartMinute) + " to " +
                  IntegerToString(configs[i].EndHour) + ":" + 
                  IntegerToString(configs[i].EndMinute));
            }
            continue;
         }

         // ================= VERIFICAR FILTRO DE NOTÍCIAS =================
         if(strategies[i].ShouldPauseDueToNews(newsFilter, currentHour, currentMinute))
         {
            if(logger)
            {
               logger.LogEvent(strategyName, "SKIP", "Paused due to news event");
               logger.LogDebug(strategyName, "TRACE", "Paused due to news event at " + IntegerToString(currentHour) + ":" + IntegerToString(currentMinute));
            }
            continue;
         }

         // ================= EXECUTAR ESTRATÉGIA =================
         TradeSignal signal = strategies[i].OnUpdate(log);

         if(signal.valid)
         {
            if(logger)
            {
               logger.LogEvent(strategyName, "SIGNAL", 
                  "Valid signal - Direction: " + signal.ToStringDirection() +
                  " TP: " + DoubleToString(signal.tpPoints, 0));
               
               logger.LogDebug(strategyName, "INFO", 
                  "Valid signal generated - Direction: " + signal.ToStringDirection() + 
                  " | TP: " + DoubleToString(signal.tpPoints, 2) + " pts | Seq: " + 
                  IntegerToString(signal.sequence));
            }

            exec.Execute(signal, log);
         }
         else
         {
            if(logger)
            {
               logger.LogEvent(strategyName, "SKIP", "No signal");
               logger.LogDebug(strategyName, "TRACE", "OnUpdate completed - No valid signal");
            }
         }
      }
   }

   // ================= SET DAILY LIMITS =================
   void SetDailyLimits(int closeHour, int closeMinute, double maxLoss, double maxProfit)
   {
      dailyLimits.SetDailyCloseTime(closeHour, closeMinute);
      dailyLimits.SetMaxDailyLoss(maxLoss);
      dailyLimits.SetMaxDailyProfit(maxProfit);
   }

   // ================= GET DAILY LIMITS =================
   CDailyLimits* GetDailyLimits()
   {
      return &dailyLimits;
   }

   // ================= GET STRATEGY COUNT =================
   int GetStrategyCount()
   {
      return strategyCount;
   }

   // ================= GET STRATEGY =================
   CBaseStrategy* GetStrategy(int index)
   {
      if(index >= 0 && index < strategyCount)
         return strategies[index];
      return NULL;
   }

   // ================= GET NEWS FILTER =================
   CNewsFilter* GetNewsFilter()
   {
      return &newsFilter;
   }
};

#endif