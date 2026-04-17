#ifndef __HEARTBEAT_HTTP_MQH__
#define __HEARTBEAT_HTTP_MQH__

#include "Logger.mqh"

class CHeartbeatHTTP
{
private:
   string serverUrl;
   int heartbeatIntervalSeconds;
   datetime lastHeartbeatTime;
   CLogger* logger;
   bool isEnabled;
   string instanceId;
   string accountNumber;
   string strategyList;

public:
   CHeartbeatHTTP()
   {
      serverUrl = "http://localhost:5000/heartbeat";
      heartbeatIntervalSeconds = 5;
      lastHeartbeatTime = 0;
      logger = NULL;
      isEnabled = false;
      instanceId = "";
      accountNumber = "";
      strategyList = "";
   }

   ~CHeartbeatHTTP()
   {
   }

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   void SetServerUrl(string url)
   {
      serverUrl = url;
      if(logger)
         logger.LogEvent("HEARTBEAT", "CONFIG", "Server URL set to: " + url);
   }

   void SetHeartbeatInterval(int seconds)
   {
      heartbeatIntervalSeconds = seconds;
      if(logger)
         logger.LogEvent("HEARTBEAT", "CONFIG", "Heartbeat interval: " + IntegerToString(seconds) + "s");
   }

   void SetInstanceId(string id)
   {
      instanceId = id;
   }

   void SetAccountNumber(string account)
   {
      accountNumber = account;
   }

   void SetStrategyList(string strategies)
   {
      strategyList = strategies;
   }

   void Enable()
   {
      isEnabled = true;
      lastHeartbeatTime = TimeCurrent();
      if(logger)
         logger.LogEvent("HEARTBEAT", "ENABLED", "Heartbeat system enabled - Interval: 5s");
   }

   void Disable()
   {
      isEnabled = false;
      if(logger)
         logger.LogEvent("HEARTBEAT", "DISABLED", "Heartbeat system disabled");
   }

   bool IsEnabled()
   {
      return isEnabled;
   }

   bool ShouldSendHeartbeat()
   {
      if(!isEnabled)
         return false;

      datetime now = TimeCurrent();
      if(now - lastHeartbeatTime >= heartbeatIntervalSeconds)
         return true;

      return false;
   }

   bool SendHeartbeat()
   {
      if(!isEnabled)
         return false;

      if(!ShouldSendHeartbeat())
         return true;

      datetime now = TimeCurrent();
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);  // ✅ CORRIGIDO: ACCOUNT_FREEMARGIN → ACCOUNT_MARGIN_FREE
      double marginUsed = AccountInfoDouble(ACCOUNT_MARGIN);
      int openPositions = PositionsTotal();

      // ✅ NOVO: Extrair trades abertos
      string openTrades = BuildOpenTradesJSON();

      // ✅ NOVO: Extrair estatísticas diárias
      string dailyStats = BuildDailyStatsJSON();

      // ✅ NOVO: Status das estratégias
      string strategyStatus = BuildStrategyStatusJSON();

      string payload = BuildHeartbeatPayload(
         now,
         equity,
         balance,
         freeMargin,
         marginUsed,
         openPositions,
         openTrades,
         dailyStats,
         strategyStatus
      );

      if(logger)
         logger.LogDebug("HEARTBEAT", "SEND", "Sending heartbeat (5s interval)");

      bool success = SendHTTPRequest(payload);

      if(success)
      {
         lastHeartbeatTime = now;
         if(logger)
            logger.LogEvent("HEARTBEAT", "SUCCESS", "Heartbeat sent - Next in 5s");
      }
      else
      {
         if(logger)
            logger.LogEvent("HEARTBEAT", "ERROR", "Failed to send heartbeat");
      }

      return success;
   }

private:

   string BuildHeartbeatPayload(
      datetime timestamp,
      double equity,
      double balance,
      double freeMargin,
      double marginUsed,
      int positions,
      string openTrades,
      string dailyStats,
      string strategyStatus
   )
   {
      // ✅ CORRIGIDO: Usar ACCOUNT_MARGIN_LEVEL ao invés de ACCOUNT_MARGIN_SO_LEVEL
      double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

      string payload = "{";
      payload += "\"timestamp\": \"" + TimeToString(timestamp, TIME_DATE|TIME_SECONDS) + "\", ";
      payload += "\"timestamp_unix\": " + IntegerToString((int)timestamp) + ", ";
      payload += "\"instance_id\": \"" + instanceId + "\", ";
      payload += "\"account_number\": " + accountNumber + ", ";
      payload += "\"account_name\": \"" + AccountInfoString(ACCOUNT_NAME) + "\", ";
      payload += "\"server_name\": \"" + AccountInfoString(ACCOUNT_SERVER) + "\", ";
      payload += "\"symbol\": \"" + _Symbol + "\", ";
      payload += "\"balance\": " + DoubleToString(balance, 2) + ", ";
      payload += "\"equity\": " + DoubleToString(equity, 2) + ", ";
      payload += "\"free_margin\": " + DoubleToString(freeMargin, 2) + ", ";
      payload += "\"margin_used\": " + DoubleToString(marginUsed, 2) + ", ";
      payload += "\"margin_level\": " + DoubleToString(marginLevel, 2) + ", ";  // ✅ CORRIGIDO
      payload += "\"ask\": " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), 5) + ", ";
      payload += "\"bid\": " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), 5) + ", ";
      payload += "\"spread\": " + IntegerToString((int)((SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) * 10000)) + ", ";  // ✅ CORRIGIDO: Cast para (int)
      payload += "\"open_positions\": " + IntegerToString(positions) + ", ";
      payload += "\"is_connected\": true, ";
      payload += "\"ea_version\": \"5.02\", ";
      payload += "\"session_start_time\": \"" + TimeToString(iTime(_Symbol, PERIOD_D1, 0), TIME_DATE|TIME_SECONDS) + "\", ";
      payload += "\"strategies\": " + strategyStatus + ", ";
      payload += "\"open_trades\": " + openTrades + ", ";
      payload += "\"daily_stats\": " + dailyStats;
      payload += "}";

      return payload;
   }

   // ✅ NOVO: Extrair trades abertos
   string BuildOpenTradesJSON()
   {
      string trades = "[";
      int count = 0;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(count > 0) trades += ",";

            string posType = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            long magicNumber = PositionGetInteger(POSITION_MAGIC);  // ✅ CORRIGIDO: long ao invés de double

            trades += "{";
            trades += "\"ticket\": " + IntegerToString((int)ticket) + ", ";
            trades += "\"strategy\": \"UNKNOWN\", ";
            trades += "\"symbol\": \"" + PositionGetString(POSITION_SYMBOL) + "\", ";
            trades += "\"type\": \"" + posType + "\", ";
            trades += "\"volume\": " + DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + ", ";
            trades += "\"entry_price\": " + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), 5) + ", ";
            trades += "\"entry_time\": \"" + TimeToString((datetime)PositionGetInteger(POSITION_TIME), TIME_DATE|TIME_SECONDS) + "\", ";
            trades += "\"stop_loss\": " + DoubleToString(PositionGetDouble(POSITION_SL), 5) + ", ";
            trades += "\"take_profit\": " + DoubleToString(PositionGetDouble(POSITION_TP), 5) + ", ";
            trades += "\"current_price\": " + DoubleToString(PositionGetDouble(POSITION_PRICE_CURRENT), 5) + ", ";
            trades += "\"unrealized_pnl\": " + DoubleToString(PositionGetDouble(POSITION_PROFIT), 2) + ", ";
            trades += "\"magic_number\": " + IntegerToString((int)magicNumber);
            trades += "}";

            count++;
         }
      }

      trades += "]";
      return trades;
   }

   // ✅ NOVO: Estatísticas diárias
   string BuildDailyStatsJSON()
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double dailyPnL = equity - balance;

      int tradesCount = 0;
      int tradesWon = 0;
      int tradesLost = 0;

      // Contar trades históricos do dia (simplificado)
      HistorySelect(TimeCurrent() - 86400, TimeCurrent()); // Últimas 24 horas

      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
         {
            double dealProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(dealProfit > 0)
               tradesWon++;
            else if(dealProfit < 0)
               tradesLost++;
            tradesCount++;
         }
      }

      double grossProfit = 0;
      double grossLoss = 0;

      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
         {
            double dealProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(dealProfit > 0)
               grossProfit += dealProfit;
            else
               grossLoss += dealProfit;
         }
      }

      double winRate = (tradesCount > 0) ? (double)tradesWon / tradesCount * 100 : 0;

      string stats = "{";
      stats += "\"trades_count\": " + IntegerToString(tradesCount) + ", ";
      stats += "\"trades_won\": " + IntegerToString(tradesWon) + ", ";
      stats += "\"trades_lost\": " + IntegerToString(tradesLost) + ", ";
      stats += "\"gross_profit\": " + DoubleToString(grossProfit, 2) + ", ";
      stats += "\"gross_loss\": " + DoubleToString(grossLoss, 2) + ", ";
      stats += "\"net_profit\": " + DoubleToString(dailyPnL, 2) + ", ";
      stats += "\"win_rate\": " + DoubleToString(winRate, 2) + ", ";
      stats += "\"max_drawdown\": 0.0";
      stats += "}";

      return stats;
   }

   // ✅ NOVO: Status das estratégias
   string BuildStrategyStatusJSON()
   {
      string status = "[";

      // Estratégia 1: 3BullGoDown
      status += "{";
      status += "\"name\": \"3BullGoDown\", ";
      status += "\"enabled\": true, ";
      status += "\"last_signal\": \"NONE\", ";
      status += "\"last_signal_time\": null, ";
      status += "\"total_trades_today\": 0, ";
      status += "\"open_trades\": " + IntegerToString(PositionsTotal());
      status += "}";

      // Estratégia 2: 3BearGoDown
      status += ",{";
      status += "\"name\": \"3BearGoDown\", ";
      status += "\"enabled\": false, ";
      status += "\"last_signal\": \"NONE\", ";
      status += "\"last_signal_time\": null, ";
      status += "\"total_trades_today\": 0, ";
      status += "\"open_trades\": 0";
      status += "}";

      // Estratégia 3: 2Bear2BullGoUp
      status += ",{";
      status += "\"name\": \"2Bear2BullGoUp\", ";
      status += "\"enabled\": false, ";
      status += "\"last_signal\": \"NONE\", ";
      status += "\"last_signal_time\": null, ";
      status += "\"total_trades_today\": 0, ";
      status += "\"open_trades\": 0";
      status += "}";

      status += "]";
      return status;
   }

   bool SendHTTPRequest(string payload)
   {
      uchar postData[];
      StringToCharArray(payload, postData);

      uchar responseBody[];
      string responseHeaders = "";
      int timeout = 5000;

      int res = WebRequest("POST", serverUrl, "", timeout, postData, responseBody, responseHeaders);

      if(res == -1)
      {
         if(logger)
            logger.LogEvent("HEARTBEAT", "HTTP_ERROR", "WebRequest failed: " + IntegerToString(GetLastError()));
         return false;
      }
      else if(res != 200)
      {
         if(logger)
            logger.LogEvent("HEARTBEAT", "HTTP_RESPONSE", "Server status: " + IntegerToString(res));
         return false;
      }

      return true;
   }

};

#endif