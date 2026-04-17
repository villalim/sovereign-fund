#ifndef __POSITION_MANAGER_MQH__
#define __POSITION_MANAGER_MQH__

#include "Logger.mqh"
#include "Types.mqh"

struct PositionInfo
{
   ulong ticket;
   string strategy;
   int magic;
   double entryPrice;
   double currentPrice;
   double profitLoss;
   double profitPercent;
   datetime openTime;
   int durationSeconds;
   int positionType;
};

class CPositionManager
{
private:
   PositionInfo positions[500];
   int positionCount;
   CLogger* logger;
   string strategyNames[10];
   int strategyPositionCount[10];

public:
   CPositionManager()
   {
      positionCount = 0;
      logger = NULL;
      for(int i = 0; i < 10; i++)
      {
         strategyNames[i] = "";
         strategyPositionCount[i] = 0;
      }
   }

   ~CPositionManager()
   {
   }

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   void RefreshPositions()
   {
      positionCount = 0;
      
      for(int i = 0; i < 10; i++)
         strategyPositionCount[i] = 0;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
         {
            if(PositionGetString(POSITION_SYMBOL) != _Symbol)
               continue;

            PositionInfo info;
            info.ticket = ticket;
            info.magic = (int)PositionGetInteger(POSITION_MAGIC);
            info.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            info.positionType = (int)PositionGetInteger(POSITION_TYPE);
            info.openTime = (datetime)PositionGetInteger(POSITION_TIME);
            info.durationSeconds = (int)(TimeCurrent() - info.openTime);

            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            info.currentPrice = (info.positionType == POSITION_TYPE_BUY) ? bid : ask;
            info.profitLoss = PositionGetDouble(POSITION_PROFIT);
            info.profitPercent = (info.profitLoss / (info.entryPrice * PositionGetDouble(POSITION_VOLUME))) * 100;

            if(positionCount < 500)
               positions[positionCount++] = info;
         }
      }

      if(logger)
         logger.LogDebug("POSITION_MGR", "REFRESH", "Refreshed positions: " + IntegerToString(positionCount));
   }

   int GetOpenPositionCount()
   {
      RefreshPositions();
      return positionCount;
   }

   int GetPositionCountByStrategy(string strategyName)
   {
      RefreshPositions();
      int count = 0;
      
      for(int i = 0; i < positionCount; i++)
      {
         if(positions[i].strategy == strategyName)
            count++;
      }
      
      return count;
   }

   int GetPositionCountByMagic(int magic)
   {
      RefreshPositions();
      int count = 0;
      
      for(int i = 0; i < positionCount; i++)
      {
         if(positions[i].magic == magic)
            count++;
      }
      
      return count;
   }

   PositionInfo GetPosition(int index)
   {
      PositionInfo empty;
      empty.ticket = 0;
      
      if(index >= 0 && index < positionCount)
         return positions[index];
      
      return empty;
   }

   double GetTotalExposure()
   {
      RefreshPositions();
      double totalExposure = 0.0;
      
      for(int i = 0; i < positionCount; i++)
      {
         totalExposure += MathAbs(positions[i].profitLoss);
      }
      
      return totalExposure;
   }

   double GetTotalProfit()
   {
      RefreshPositions();
      double totalProfit = 0.0;
      
      for(int i = 0; i < positionCount; i++)
      {
         totalProfit += positions[i].profitLoss;
      }
      
      return totalProfit;
   }

   double GetAverageProfit()
   {
      if(positionCount == 0)
         return 0.0;
      
      return GetTotalProfit() / positionCount;
   }

   string GetPositionDetails(int index)
   {
      if(index < 0 || index >= positionCount)
         return "";
      
      PositionInfo info = positions[index];
      string details = "Ticket=" + (string)info.ticket;
      details += " | Magic=" + IntegerToString(info.magic);
      details += " | Entry=" + DoubleToString(info.entryPrice, 5);
      details += " | Current=" + DoubleToString(info.currentPrice, 5);
      details += " | P&L=" + DoubleToString(info.profitLoss, 2);
      details += " | Duration=" + IntegerToString(info.durationSeconds) + "s";
      
      return details;
   }

   void LogPositionSummary()
   {
      RefreshPositions();
      
      if(logger)
      {
         logger.LogEvent("POSITION_MGR", "SUMMARY", 
            "Total Positions: " + IntegerToString(positionCount) +
            " | Total P&L: " + DoubleToString(GetTotalProfit(), 2) +
            " | Exposure: " + DoubleToString(GetTotalExposure(), 2));
      }
   }
};

#endif