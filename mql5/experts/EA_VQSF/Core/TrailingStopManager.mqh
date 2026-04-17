#ifndef __TRAILING_STOP_MANAGER_MQH__
#define __TRAILING_STOP_MANAGER_MQH__

#include "Logger.mqh"

class CTrailingStopManager
{
private:
   long ticket;
   string strategyName;
   double tpPoints;
   double slPoints;
   double entryPrice;
   double maxTPPoints;
   bool isBuy;
   double activationPercent;
   bool activated;
   double bestPrice;
   double currentSL;
   double currentTP;

public:
   CTrailingStopManager()
   {
      ticket = 0;
      strategyName = "";
      tpPoints = 0;
      slPoints = 0;
      entryPrice = 0;
      maxTPPoints = 0;
      isBuy = true;
      activationPercent = 50.0;
      activated = false;
      bestPrice = 0;
      currentSL = 0;
      currentTP = 0;
   }

   ~CTrailingStopManager()
   {
   }

   void Initialize(long tick, string strategy, double tp, double sl, 
                   double entry, double maxTP, bool buy, double activation)
   {
      ticket = tick;
      strategyName = strategy;
      tpPoints = tp;
      slPoints = sl;
      entryPrice = entry;
      maxTPPoints = maxTP;
      isBuy = buy;
      activationPercent = activation;
      activated = false;
      bestPrice = entry;
      currentSL = sl;
      currentTP = tp;
   }

   bool Update(double currentPrice, CLogger &log)
   {
      if(ticket <= 0)
         return false;

      bestPrice = isBuy ? MathMax(bestPrice, currentPrice) : MathMin(bestPrice, currentPrice);

      if(!activated)
      {
         double activationLevel = (tpPoints * activationPercent) / 100.0;
         double priceMovement = isBuy ? (bestPrice - entryPrice) / _Point : 
                                (entryPrice - bestPrice) / _Point;

         if(priceMovement >= activationLevel)
         {
            activated = true;
            currentSL = 0;
            log.LogDebug(strategyName, "TS_ACTIVATED", "Ticket=" + (string)ticket);
         }
      }

      return activated;
   }

   long GetTicket() { return ticket; }
   bool IsActivated() { return activated; }
   double GetBestPrice() { return bestPrice; }
   double GetCurrentSL() { return currentSL; }
   double GetCurrentTP() { return currentTP; }

   void Deactivate()
   {
      ticket = 0;
      activated = false;
   }

   string GetDebugInfo()
   {
      return "Ticket=" + (string)ticket + " | TS=" + (activated ? "ACTIVE" : "INACTIVE") + 
             " | BestPrice=" + DoubleToString(bestPrice, 5);
   }
};

#endif