#ifndef __TRADE_EXECUTOR_MQH__
#define __TRADE_EXECUTOR_MQH__

#include "../Core/Types.mqh"
#include "../Core/Utils.mqh"
#include "../Core/Logger.mqh"
#include "../Core/StrategyHelper.mqh"
#include "../Core/NewsFilter.mqh"
#include "../Core/TrailingStopManager.mqh"
#include "../Core/TrailingStopLogger.mqh"
#include "../Core/TrailingStopMetrics.mqh"
#include "../Core/RiskManager.mqh"
#include <Trade/Trade.mqh>

class CTradeExecutor
{
private:
   CTrade trade;
   TradeRecord records[1000];
   int recordCount;
   CLogger *logger;
   CRiskManager *riskManager;
   CTrailingStopManager *trailingStops[500];
   int trailingStopCount;
   CTrailingStopLogger *tsLogger;
   
   void CaptureMarketFeatures(TradeRecord &rec)
   {
      rec.atr = CStrategyHelper::GetATR(14, PERIOD_M15);
      rec.volatility = CStrategyHelper::CalculateVolatility(20, PERIOD_M15);
      rec.rsi = CStrategyHelper::GetRSI(14, PERIOD_M15);
      rec.trend = CStrategyHelper::GetTrend(14, PERIOD_M15);
      rec.accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   }

public:
   CTradeExecutor()
   {
      recordCount = 0;
      logger = NULL;
      riskManager = NULL;
      trailingStopCount = 0;
      tsLogger = NULL;      

      for(int i = 0; i < 100; i++)
         trailingStops[i] = NULL;
   }

   ~CTradeExecutor()
   {
      for(int i = 0; i < trailingStopCount; i++)
      {
         if(trailingStops[i] != NULL)
            delete trailingStops[i];
      }
   }

   void SetLogger(CLogger *log)
   {
      logger = log;
   }
   // ================= NOVO: SET RISK MANAGER =================
   void SetRiskManager(CRiskManager *rm)
   {
      riskManager = rm;
      if(logger)
         logger.LogEvent("EXECUTOR", "INIT", "RiskManager assigned");
   }

   void SetTrailingStopLogger(CTrailingStopLogger *tsLog)
   {
      tsLogger = tsLog;
   }
   // ================= EXECUTE WITH RISK MANAGEMENT =================
   void Execute(TradeSignal &signal, CLogger &log)
   {
      log.LogDebug(signal.strategyName, "EXEC_START", "Execute() called | Magic: " + IntegerToString(signal.magicNumber));      

      if(!signal.valid) 
      {
         log.LogDebug(signal.strategyName, "EXEC_INVALID", "Signal not valid - returning");
         return;
      }   

      log.LogDebug(signal.strategyName, "EXEC_VALID", "Signal is valid");   

      if(HasPosition(signal.magicNumber))
      {
         log.LogDebug(signal.strategyName, "EXEC_POSITION_EXISTS", 
            "Position already exists for magic=" + IntegerToString(signal.magicNumber));
         return;
      }   

      log.LogDebug(signal.strategyName, "EXEC_NO_POSITION", "No existing position - proceeding with order");      

      double maxAcceptableSpread = 100; 

      if(signal.spread > maxAcceptableSpread)
      {
         log.LogDebug(signal.strategyName, "EXEC_SPREAD_HIGH", "Spread too high: " + DoubleToString(signal.spread, 1) + " > " + 
            DoubleToString(maxAcceptableSpread, 1));            

         log.LogEvent(signal.strategyName, "SKIP",
            "Spread too high: " + DoubleToString(signal.spread, 1) + " > " + 
            DoubleToString(maxAcceptableSpread, 1));
         return;
      }      

      // ================= NOVO: CALCULAR LOTE DINAMICAMENTE =================
      double calculatedLot = signal.lot;  // Default = lote fixo      

      if(riskManager != NULL)
      {
         calculatedLot = riskManager.CalculateLotSize(signal.slPoints, signal.strategyName, signal.lot);         

         log.LogDebug(signal.strategyName, "LOT_CALCULATED",
            "FixedLot: " + DoubleToString(signal.lot, 2) +
            " | CalculatedLot: " + DoubleToString(calculatedLot, 2));
      }
      else
      {
         log.LogEvent("EXECUTOR", "WARNING", "RiskManager not initialized - using fixed lot");
      }      

      // ================= NOVO: CALCULAR RISCO DA POSIÇÃO =================
      double entryPrice = 0.0;      

      if(signal.direction == BUY)
         entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      else if(signal.direction == SELL)
         entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      else
      {
         log.LogDebug(signal.strategyName, "EXEC_INVALID_DIRECTION", "Invalid direction: " + IntegerToString(signal.direction));
         return;
      }      

      double stopLossPrice = 0.0;
      if(signal.direction == BUY)
         stopLossPrice = entryPrice - (signal.slPoints * _Point);
      else
         stopLossPrice = entryPrice + (signal.slPoints * _Point);      

      double positionRisk = riskManager != NULL ? 
         riskManager.CalculatePositionRisk(calculatedLot, entryPrice, stopLossPrice) : 0.0;

      log.LogDebug(signal.strategyName, "POSITION_RISK_CALC",
         "EntryPrice: " + DoubleToString(entryPrice, 5) +
         " | StopLoss: " + DoubleToString(stopLossPrice, 5) +
         " | PositionRisk: " + DoubleToString(positionRisk, 2));      

      // ================= NOVO: VALIDAR RISCO COM CanOpenPosition =================
      if(riskManager != NULL)
      {
         if(!riskManager.CanOpenPosition(positionRisk, calculatedLot))
         {
            log.LogEvent(signal.strategyName, "POSITION_BLOCKED",
               "Risk validation failed - position rejected");
            return;  // Posição rejeitada por validação de risco
         }         

         log.LogDebug(signal.strategyName, "RISK_VALIDATION_PASSED",
            "Position passed risk validation | Risk: " + DoubleToString(positionRisk, 2) +
            " | Lot: " + DoubleToString(calculatedLot, 2));
      } 

      // ================= ENVIAR ORDEM COM LOTE CALCULADO =================
      trade.SetExpertMagicNumber(signal.magicNumber);   

      bool result = false;   

      if(signal.direction == BUY)
      {
         log.LogDebug(signal.strategyName, "EXEC_BUY_ORDER", "Sending BUY order | Lot: " + DoubleToString(calculatedLot, 2));
         result = trade.Buy(calculatedLot, _Symbol);
      }
      else if(signal.direction == SELL)
      {
         log.LogDebug(signal.strategyName, "EXEC_SELL_ORDER", "Sending SELL order | Lot: " + DoubleToString(calculatedLot, 2));
         result = trade.Sell(calculatedLot, _Symbol);
      }
      else
      {
         log.LogDebug(signal.strategyName, "EXEC_INVALID_DIRECTION", "Invalid direction: " + IntegerToString(signal.direction));
         return;
      }   

      if(!result)
      {
         int err = GetLastError();
         log.LogDebug(signal.strategyName, "EXEC_ORDER_FAILED", 
            "Order failed | Error: " + IntegerToString(err) + " | Description: " + GetErrorDescription(err));
         return;
      }   

      log.LogDebug(signal.strategyName, "EXEC_ORDER_SUCCESS", "Order sent successfully");   

      for(int i = 0; i < 10; i++)
      {
         if(SelectPositionByMagic(signal.magicNumber))
         {
            log.LogDebug(signal.strategyName, "EXEC_POSITION_FOUND", "Position found at attempt " + IntegerToString(i+1));
            break;
         }
         Sleep(50);
      }   

      if(!SelectPositionByMagic(signal.magicNumber))
      {
         log.LogDebug(signal.strategyName, "EXEC_POSITION_NOT_FOUND", "Position not found after 10 attempts");
         return;
      }   

      long ticket = PositionGetInteger(POSITION_TICKET);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      signal.tradeId = ticket;   

      log.LogDebug(signal.strategyName, "EXEC_POSITION_DETAILS", 
         "Ticket: " + (string)ticket + " | Open: " + DoubleToString(open, 5));   

      double sl, tp;   

      if(signal.direction == BUY)
      {
         sl = NormalizeDouble(open - signal.slPoints * _Point, _Digits);
         tp = NormalizeDouble(open + signal.tpPoints * _Point, _Digits);
      }
      else
      {
         sl = NormalizeDouble(open + signal.slPoints * _Point, _Digits);
         tp = NormalizeDouble(open - signal.tpPoints * _Point, _Digits);
      }   

      log.LogDebug(signal.strategyName, "EXEC_SL_TP", 
         "SL: " + DoubleToString(sl, 5) + " | TP: " + DoubleToString(tp, 5));         

      log.LogDebug(signal.strategyName, "EXEC_MODIFY_START", 
         "Attempting PositionModify | Ticket: " + (string)ticket + 
         " | SL: " + DoubleToString(sl, 5) + " | TP: " + DoubleToString(tp, 5));   

      bool modifySuccess = false;
      for(int retry = 0; retry < 3; retry++)
      {
         if(trade.PositionModify(ticket, sl, tp))
         {
            modifySuccess = true;
            break;
         }
         Sleep(100);
      }      

      if(!modifySuccess)
      {
         log.LogEvent(signal.strategyName, "MODIFY_FAILED", 
            "Could not modify ticket " + (string)ticket);
         return;
      }   

      log.LogEvent(signal.strategyName, "TRADE_OPEN", "ticket=" + (string)signal.tradeId);   

      log.LogDebug(signal.strategyName, "EXEC_MODIFY_SUCCESS", 
         "PositionModify successful | Ticket: " + (string)ticket);   

      log.LogEvent(signal.strategyName, "TRADE_OPEN", 
         "ticket=" + (string)signal.tradeId + " | Open=" + DoubleToString(open, 5) + " | Lot=" + DoubleToString(calculatedLot, 2));   

      // ================= CRIAR TRADE RECORD =================
      TradeRecord rec;
      rec.tradeId = signal.tradeId;
      rec.strategy = signal.strategyName;
      rec.sequence = signal.sequence;
      rec.candleSize = signal.candleSize;
      rec.upperWick = signal.upperWick;
      rec.lowerWick = signal.lowerWick;
      rec.spread = signal.spread;
      rec.openTime = TimeCurrent();
      rec.totalMove = signal.totalMove;
      rec.largestCandle = signal.largestCandle;
      rec.minSequenceUsed = signal.minSequenceUsed;
      rec.atr = signal.atr;
      rec.volatility = signal.volatility;
      rec.rsi = signal.rsi;
      rec.trend = signal.trend;
      rec.accountEquity = signal.accountEquity;   

      if(recordCount < 1000)
         records[recordCount++] = rec;   

      log.LogDebug(signal.strategyName, "EXEC_RECORD_SAVED", 
         "Trade record saved | Count: " + IntegerToString(recordCount));   

      // ================= TRAILING STOP =================
      if(signal.enableTrailingStop)
      {
         log.LogDebug(signal.strategyName, "EXEC_TS_ADDING", 
            "Adding trailing stop for ticket: " + (string)ticket);         

         bool isBuy = (signal.direction == BUY);
         AddTrailingStop(ticket, signal.strategyName, signal.tpPoints, signal.slPoints,
                         open, signal.maxTakeProfit, isBuy, signal.trailingStopActivationPercent, log);   

         log.LogDebug(signal.strategyName, "EXEC_TS_ADDED", "Trailing stop added successfully");
      }   

      log.LogDebug(signal.strategyName, "EXEC_COMPLETE", 
         "Execute() completed successfully | Ticket: " + (string)ticket + " | Lot: " + DoubleToString(calculatedLot, 2));
   }     

   // ================= HELPER: Get Error Description =================
   string GetErrorDescription(int errorCode)
   {
      switch(errorCode)
      {
         case 0: return "No error (0)";
         case 130: return "Invalid stops - too close to price (130)";
         case 131: return "Invalid trade volume (131)";
         case 134: return "Not enough money (134)";
         case 138: return "Requote (138)";
         case 141: return "Too many requests (141)";
         case 145: return "Modification denied by broker (145)";
         case 146: return "Trade context is busy (146)";
         case 150: return "Order is expired (150)";
         case 1: return "Unspecified internal error (1)";
         default: return "Error code: " + IntegerToString(errorCode);
      }
   }

   void ProcessTrades(CLogger &log)
   {
      UpdateTrailingStops(log);
      CheckClosedTrades(log);
   }

   bool HasPosition(long magic)
   {
      return SelectPositionByMagic(magic);
   }

   bool SelectPositionByMagic(long magic)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
         {
            if(PositionGetInteger(POSITION_MAGIC) == magic && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
               return true;
            }
         }
      }
      return false;
   }

void CheckClosedTrades(CLogger &log)
{
   static ulong lastHistoryCheck = 0;
   int deals = HistoryDealsTotal();
   
   log.LogDebug("EXECUTOR", "CHECK_CLOSED", "Checking closed trades | Total deals: " + IntegerToString(deals) + " | LastCheck: " + (string)lastHistoryCheck);
   
   for(int i = deals - 1; i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      
      // CORRIGIDO: Pular apenas deals JÁ PROCESSADOS
      if(dealTicket <= lastHistoryCheck)
      {
         log.LogDebug("EXECUTOR", "SKIP_DEAL", "Skipping already processed deal: " + (string)dealTicket);
         continue;
      }
      
      // Atualizar IMEDIATAMENTE ao encontrar novo deal
      if(dealTicket > lastHistoryCheck)
         lastHistoryCheck = dealTicket;
      
      if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
      {
         string symbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
         if(symbol != _Symbol)
            continue;
         
         double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         long positionId = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
         datetime closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         double closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         
         log.LogEvent("EXECUTOR", "TRADE_CLOSED", 
            "Ticket=" + (string)positionId + 
            " | Magic=" + (string)magic + 
            " | ClosePrice=" + DoubleToString(closePrice, 5) + 
            " | Profit=" + DoubleToString(profit, 2));
         
         log.LogDebug("EXECUTOR", "DEAL_DETAILS", 
            "Deal=" + (string)dealTicket + 
            " | Position=" + (string)positionId + 
            " | Time=" + TimeToString(closeTime) + 
            " | Profit=" + DoubleToString(profit, 2));
         
         DeactivateTrailingStop(positionId, log);
         
         for(int j = 0; j < recordCount; j++)
         {
            if(records[j].tradeId == positionId)
            {
               records[j].profit = profit;
               records[j].profitPercent = (profit / records[j].accountEquity) * 100;
               records[j].label = (profit > 0) ? 1 : 0;
               records[j].closeTime = TimeCurrent();
               records[j].durationMinutes = (int)((records[j].closeTime - records[j].openTime) / 60);
               
               log.LogEvent("EXECUTOR", "RECORD_UPDATED", 
                  "Trade record updated | Ticket: " + (string)positionId + 
                  " | Profit: " + DoubleToString(profit, 2));
               
               SaveToCSV(records[j], log);
               break;
            }
         }
      }
   }
}

   void CloseTradesDueToNews(CNewsFilter &newsFilter, CLogger &log)
   {
      datetime now = TimeCurrent();
      MqlDateTime timeStruct;
      TimeToStruct(now, timeStruct);
      int currentHour = timeStruct.hour;
      int currentMinute = timeStruct.min;
      if(!newsFilter.ShouldCloseTrades(currentHour, currentMinute))
         return;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
               if(trade.PositionClose(ticket))
               {
                  log.LogEvent("NEWS_FILTER", "CLOSE_TRADE", "Closed position " + (string)ticket);
               }
            }
         }
      }
   }

   void CloseAllTrades(CLogger &log)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);

         if(PositionSelectByTicket(ticket))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
               if(trade.PositionClose(ticket))
               {
                  log.LogEvent("DAILY_LIMITS", "CLOSE_ALL", "Closed position " + (string)ticket);
               }
            }
         }
      }
   }

   void SaveToCSV(TradeRecord &rec, CLogger &log)
   {
      log.LogFeatures(rec.strategy, rec.sequence, rec.candleSize, rec.upperWick, rec.lowerWick, rec.spread, rec.profit, rec.label > 0);
   }

   TradeRecord GetRecord(int index)
   {
      if(index >= 0 && index < recordCount)
         return records[index];

      TradeRecord empty;
      empty.Reset();

      return empty;
   }

   int GetRecordCount()
   {
      return recordCount;
   }   

   void AddTrailingStop(long ticket, string strategyName, double tpPoints, double slPoints, 
                        double entryPrice, double maxTPPoints, bool isBuy, 
                        double activationPercent, CLogger &log)
   {
      if(trailingStopCount >= 100)
      {
         log.LogDebug(strategyName, "ERROR", "Max trailing stops reached");
         return;
      }

      trailingStops[trailingStopCount] = new CTrailingStopManager();      

      if(trailingStops[trailingStopCount] == NULL)
      {
         log.LogDebug(strategyName, "ERROR", "Failed to allocate TS");
         return;
      }

      trailingStops[trailingStopCount].Initialize(ticket, strategyName, tpPoints, slPoints, entryPrice, maxTPPoints, isBuy, activationPercent);
      trailingStopCount++;      

      log.LogDebug(strategyName, "INFO", "TS initialized for ticket=" + (string)ticket);
   }

   void UpdateTrailingStops(CLogger &log)
   {
      log.LogEvent("EXECUTOR", "TS_UPDATE", "Updating " + IntegerToString(trailingStopCount) + " trailing stops");

      for(int i = 0; i < trailingStopCount; i++)
      {
         if(trailingStops[i] == NULL)
            continue;

         long ticket = trailingStops[i].GetTicket();      
         
         if(ticket <= 0)
            continue;

         if(PositionSelectByTicket(ticket))
         {
            double currentPrice = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                                  SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                                  
            log.LogDebug("EXECUTOR", "TS_CHECK", "Ticket: " + (string)ticket + " | Current Price: " + DoubleToString(currentPrice, 5));
            trailingStops[i].Update(currentPrice, log);
         }
      }
   }

   void DeactivateTrailingStop(long ticket, CLogger &log)
   {
      for(int i = 0; i < trailingStopCount; i++)
      {
         if(trailingStops[i] != NULL && trailingStops[i].GetTicket() == ticket)
         {
            // Quando TS fecha posição
            log.LogEvent("EXECUTOR", "TS_CLOSE", "Trailing stop closed ticket: " + (string)ticket);
            trailingStops[i].Deactivate();
            break;
         }
      }
   }    

};
#endif