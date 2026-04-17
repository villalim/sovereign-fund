#ifndef __TRAILING_STOP_LOGGER_MQH__
#define __TRAILING_STOP_LOGGER_MQH__

#include "Logger.mqh"
#include "Types.mqh"

class CTrailingStopLogger
{
private:
   CLogger* logger;
   string logFile;
   int handle;
   bool fileEnabled;

public:
   CTrailingStopLogger()
   {
      logger = NULL;
      logFile = "TrailingStop_Events.log";
      handle = -1;
      fileEnabled = true;
   }

   ~CTrailingStopLogger()
   {
      if(handle != -1)
         FileClose(handle);
   }

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   void SetLogFile(string filename)
   {
      logFile = filename;
   }

   // ================= LOG TS INITIALIZATION =================
   void LogTSInitialization(long ticket, string strategyName, double tpPoints, double slPoints, 
                            double activationPercent, bool isBuy)
   {
      string direction = isBuy ? "BUY" : "SELL";
      string message = "TS_INIT | Ticket=" + IntegerToString(ticket) + 
                       " | Strategy=" + strategyName + 
                       " | Direction=" + direction +
                       " | TP=" + DoubleToString(tpPoints, 2) + "pts" +
                       " | SL=" + DoubleToString(slPoints, 2) + "pts" +
                       " | ActivationPercent=" + DoubleToString(activationPercent, 1) + "%";

      LogToFile(message);
      if(logger)
         logger.LogEvent(strategyName, "TS_INIT", "Activation percent: " + DoubleToString(activationPercent, 1) + "%");
   }

   // ================= LOG TS ACTIVATION =================
   void LogTSActivation(long ticket, string strategyName, double priceMovement, 
                        double activationLevel, double currentTP)
   {
      string message = "TS_ACTIVATED | Ticket=" + IntegerToString(ticket) + 
                       " | Strategy=" + strategyName +
                       " | PriceMovement=" + DoubleToString(priceMovement, 2) + "pts" +
                       " | ActivationLevel=" + DoubleToString(activationLevel, 2) + "pts" +
                       " | CurrentTP=" + DoubleToString(currentTP, 2) + "pts" +
                       " | SL=BREAKEVEN";

      LogToFile(message);
      if(logger)
         logger.LogEvent(strategyName, "TS_ACTIVATED", "Moved SL to breakeven | TP=" + DoubleToString(currentTP, 2));
   }

   // ================= LOG TS ADJUSTMENT =================
   void LogTSAdjustment(long ticket, string strategyName, int progressLevel, 
                        double newSL, double newTP, double priceMovement)
   {
      string message = "TS_ADJUSTED | Ticket=" + IntegerToString(ticket) + 
                       " | Strategy=" + strategyName +
                       " | ProgressLevel=" + IntegerToString(progressLevel) + "%" +
                       " | SL=" + DoubleToString(newSL, 2) + "pts" +
                       " | TP=" + DoubleToString(newTP, 2) + "pts" +
                       " | PriceMovement=" + DoubleToString(priceMovement, 2) + "pts";

      LogToFile(message);
      if(logger)
         logger.LogEvent(strategyName, "TS_ADJUSTED", "Level=" + IntegerToString(progressLevel) + "% | SL=" + DoubleToString(newSL, 2) + " | TP=" + DoubleToString(newTP, 2));
   }

   // ================= LOG TS DEACTIVATION =================
   void LogTSDeactivation(long ticket, string strategyName, double finalProfit, 
                          double finalSL, double finalTP, string reason)
   {
      string message = "TS_DEACTIVATED | Ticket=" + IntegerToString(ticket) + 
                       " | Strategy=" + strategyName +
                       " | Reason=" + reason +
                       " | FinalProfit=" + DoubleToString(finalProfit, 2) + "pts" +
                       " | FinalSL=" + DoubleToString(finalSL, 2) + "pts" +
                       " | FinalTP=" + DoubleToString(finalTP, 2) + "pts";

      LogToFile(message);
      if(logger)
         logger.LogEvent(strategyName, "TS_DEACTIVATED", "Reason=" + reason + " | Profit=" + DoubleToString(finalProfit, 2));
   }

   // ================= LOG TS NO ADJUSTMENT (Progress tracking) =================
   void LogTSProgress(long ticket, string strategyName, double progressPercent, 
                      double priceMovement, double currentSL, double currentTP)
   {
      string message = "TS_PROGRESS | Ticket=" + IntegerToString(ticket) + 
                       " | Strategy=" + strategyName +
                       " | Progress=" + DoubleToString(progressPercent, 1) + "%" +
                       " | PriceMove=" + DoubleToString(priceMovement, 2) + "pts" +
                       " | SL=" + DoubleToString(currentSL, 2) + "pts" +
                       " | TP=" + DoubleToString(currentTP, 2) + "pts";

      LogToFile(message);
   }

   // ================= INTERNAL: LOG TO FILE =================
   void LogToFile(string message)
   {
      if(!fileEnabled)
         return;

      string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      string fullMessage = "[" + timestamp + "] " + message;

      handle = FileOpen(logFile, FILE_WRITE|FILE_TXT|FILE_SHARE_WRITE);

      if(handle != INVALID_HANDLE)
      {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, fullMessage);
         FileClose(handle);
      }
   }

   // ================= SUMMARY STATISTICS =================
   string GetSummaryLog()
   {
      return "TrailingStop Logger active | File: " + logFile;
   }
};

#endif