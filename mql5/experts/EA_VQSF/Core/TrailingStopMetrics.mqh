#ifndef __TRAILING_STOP_METRICS_MQH__
#define __TRAILING_STOP_METRICS_MQH__

#include "Types.mqh"
#include "Logger.mqh"

class CTrailingStopMetrics
{
private:
   struct TSMetricsData
   {
      int totalTrades;
      int tradesWithTS;
      int tradesWithoutTS;
      int successfulTSActivations;
      int failedTSActivations;
      double totalProfitWithTS;
      double totalProfitWithoutTS;
      double averageProfitWithTS;
      double averageProfitWithoutTS;
      double maxDrawdownWithTS;
      double maxDrawdownWithoutTS;
      double winRateWithTS;
      double winRateWithoutTS;
      int winsWithTS;
      int lossesWithTS;
      int winsWithoutTS;
      int lossesWithoutTS;
   };

   TSMetricsData metrics;
   CLogger* logger;

public:
   CTrailingStopMetrics()
   {
      logger = NULL;
      ResetMetrics();
   }

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   // ================= RESET METRICS =================
   void ResetMetrics()
   {
      metrics.totalTrades = 0;
      metrics.tradesWithTS = 0;
      metrics.tradesWithoutTS = 0;
      metrics.successfulTSActivations = 0;
      metrics.failedTSActivations = 0;
      metrics.totalProfitWithTS = 0;
      metrics.totalProfitWithoutTS = 0;
      metrics.averageProfitWithTS = 0;
      metrics.averageProfitWithoutTS = 0;
      metrics.maxDrawdownWithTS = 999999.0;
      metrics.maxDrawdownWithoutTS = 999999.0;      
      metrics.winRateWithTS = 0;
      metrics.winRateWithoutTS = 0;
      metrics.winsWithTS = 0;
      metrics.lossesWithTS = 0;
      metrics.winsWithoutTS = 0;
      metrics.lossesWithoutTS = 0;
   }

   // ================= RECORD TRADE WITH TS =================
   void RecordTradeWithTS(double profit, bool activated)
   {
      metrics.totalTrades++;
      metrics.tradesWithTS++;

      if(activated)
      {
         metrics.successfulTSActivations++;
         if(profit > 0)
            metrics.winsWithTS++;
         else
            metrics.lossesWithTS++;
      }
      else
      {
         metrics.failedTSActivations++;
      }

      metrics.totalProfitWithTS += profit;
      UpdateAverageProfitWithTS();
      UpdateWinRateWithTS();

      if(logger)
         logger.LogDebug("METRICS", "TS_TRADE", "Profit=" + DoubleToString(profit, 2) + " | Activated=" + (activated ? "true" : "false"));
   }

   // ================= RECORD TRADE WITHOUT TS =================
   void RecordTradeWithoutTS(double profit)
   {
      metrics.totalTrades++;
      metrics.tradesWithoutTS++;

      if(profit > 0)
         metrics.winsWithoutTS++;
      else
         metrics.lossesWithoutTS++;

      metrics.totalProfitWithoutTS += profit;
      UpdateAverageProfitWithoutTS();
      UpdateWinRateWithoutTS();

      if(logger)
         logger.LogDebug("METRICS", "NO_TS_TRADE", "Profit=" + DoubleToString(profit, 2));
   }

   // ================= UPDATE DRAWDOWN =================
   void UpdateMaxDrawdownWithTS(double drawdown)
   {
      if(drawdown < metrics.maxDrawdownWithTS)
         metrics.maxDrawdownWithTS = drawdown;
   }

   void UpdateMaxDrawdownWithoutTS(double drawdown)
   {
      if(drawdown < metrics.maxDrawdownWithoutTS)
         metrics.maxDrawdownWithoutTS = drawdown;
   }

   // ================= INTERNAL: UPDATE AVERAGES =================
   void UpdateAverageProfitWithTS()
   {
      if(metrics.tradesWithTS > 0)
         metrics.averageProfitWithTS = metrics.totalProfitWithTS / metrics.tradesWithTS;
   }

   void UpdateAverageProfitWithoutTS()
   {
      if(metrics.tradesWithoutTS > 0)
         metrics.averageProfitWithoutTS = metrics.totalProfitWithoutTS / metrics.tradesWithoutTS;
   }

   void UpdateWinRateWithTS()
   {
      if(metrics.tradesWithTS > 0)
         metrics.winRateWithTS = ((double)metrics.winsWithTS / (double)metrics.tradesWithTS) * 100.0;
   }

   void UpdateWinRateWithoutTS()
   {
      if(metrics.tradesWithoutTS > 0)
         metrics.winRateWithoutTS = ((double)metrics.winsWithoutTS / (double)metrics.tradesWithoutTS) * 100.0;
   }

   // ================= GETTERS =================
   int GetTotalTrades() { return metrics.totalTrades; }
   int GetTradesWithTS() { return metrics.tradesWithTS; }
   int GetTradesWithoutTS() { return metrics.tradesWithoutTS; }
   int GetSuccessfulTSActivations() { return metrics.successfulTSActivations; }
   int GetFailedTSActivations() { return metrics.failedTSActivations; }

   double GetTotalProfitWithTS() { return metrics.totalProfitWithTS; }
   double GetTotalProfitWithoutTS() { return metrics.totalProfitWithoutTS; }
   double GetAverageProfitWithTS() { return metrics.averageProfitWithTS; }
   double GetAverageProfitWithoutTS() { return metrics.averageProfitWithoutTS; }

   double GetWinRateWithTS() { return metrics.winRateWithTS; }
   double GetWinRateWithoutTS() { return metrics.winRateWithoutTS; }
   double GetMaxDrawdownWithTS() { return metrics.maxDrawdownWithTS; }
   double GetMaxDrawdownWithoutTS() { return metrics.maxDrawdownWithoutTS; }

   // ================= PERFORMANCE COMPARISON =================
   double GetTSPerformanceImprovement()
   {
      if(metrics.averageProfitWithoutTS == 0)
         return 0;

      return ((metrics.averageProfitWithTS - metrics.averageProfitWithoutTS) / 
              MathAbs(metrics.averageProfitWithoutTS)) * 100.0;
   }

   // ================= DETAILED REPORT =================
   string GetDetailedReport()
   {
      string report = "\n=== TRAILING STOP PERFORMANCE METRICS ===\n";
      
      report += "Total Trades: " + IntegerToString(metrics.totalTrades) + "\n";
      report += "  - With TS: " + IntegerToString(metrics.tradesWithTS) + "\n";
      report += "  - Without TS: " + IntegerToString(metrics.tradesWithoutTS) + "\n\n";

      report += "TS Activations:\n";
      report += "  - Successful: " + IntegerToString(metrics.successfulTSActivations) + "\n";
      report += "  - Failed: " + IntegerToString(metrics.failedTSActivations) + "\n\n";

      report += "Profitability (WITH TS):\n";
      report += "  - Total Profit: " + DoubleToString(metrics.totalProfitWithTS, 2) + " pts\n";
      report += "  - Average Profit: " + DoubleToString(metrics.averageProfitWithTS, 2) + " pts\n";
      report += "  - Win Rate: " + DoubleToString(metrics.winRateWithTS, 1) + "% (" + IntegerToString(metrics.winsWithTS) + "W/" + IntegerToString(metrics.lossesWithTS) + "L)\n";
      report += "  - Max Drawdown: " + DoubleToString(metrics.maxDrawdownWithTS, 2) + " pts\n\n";

      report += "Profitability (WITHOUT TS):\n";
      report += "  - Total Profit: " + DoubleToString(metrics.totalProfitWithoutTS, 2) + " pts\n";
      report += "  - Average Profit: " + DoubleToString(metrics.averageProfitWithoutTS, 2) + " pts\n";
      report += "  - Win Rate: " + DoubleToString(metrics.winRateWithoutTS, 1) + "% (" + IntegerToString(metrics.winsWithoutTS) + "W/" + IntegerToString(metrics.lossesWithoutTS) + "L)\n";
      report += "  - Max Drawdown: " + DoubleToString(metrics.maxDrawdownWithoutTS, 2) + " pts\n\n";

      report += "TS Performance Improvement: " + DoubleToString(GetTSPerformanceImprovement(), 2) + "%\n";
      report += "========================================\n";

      return report;
   }

   // ================= SUMMARY REPORT =================
   string GetSummaryReport()
   {
      return "TS: " + IntegerToString(metrics.tradesWithTS) + " trades | " +
             "Avg Profit: " + DoubleToString(metrics.averageProfitWithTS, 2) + "pts | " +
             "Win Rate: " + DoubleToString(metrics.winRateWithTS, 1) + "% | " +
             "Improvement vs No-TS: " + DoubleToString(GetTSPerformanceImprovement(), 1) + "%";
   }
};

#endif