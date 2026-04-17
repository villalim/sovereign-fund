#ifndef __BRIDGE_HTTP_MQH__
#define __BRIDGE_HTTP_MQH__

#include "Logger.mqh"

class CBridgeHTTP
{
private:
   string serverUrl;
   CLogger* logger;
   bool isConnected;
   int maxRetries;
   int retryDelayMs;

public:
   CBridgeHTTP()
   {
      serverUrl = "http://localhost:5000";
      logger = NULL;
      isConnected = false;
      maxRetries = 3;
      retryDelayMs = 1000;
   }

   ~CBridgeHTTP()
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
         logger.LogEvent("BRIDGE", "CONFIG", "Server URL: " + url);
   }

   void SetMaxRetries(int retries)
   {
      maxRetries = retries;
   }

   void SetRetryDelay(int ms)
   {
      retryDelayMs = ms;
   }

   bool Connect()
   {
      if(logger)
         logger.LogEvent("BRIDGE", "CONNECT", "Attempting connection to: " + serverUrl);

      if(TestConnection())
      {
         isConnected = true;
         if(logger)
            logger.LogEvent("BRIDGE", "CONNECTED", "Successfully connected to server");
         return true;
      }

      isConnected = false;
      if(logger)
         logger.LogEvent("BRIDGE", "CONNECT_FAILED", "Failed to connect to server");
      return false;
   }

   bool IsConnected()
   {
      return isConnected;
   }

   void Disconnect()
   {
      isConnected = false;
      if(logger)
         logger.LogEvent("BRIDGE", "DISCONNECTED", "Disconnected from server");
   }

   bool SendTradeSignal(string strategyName, string direction, double entryPrice, double stopLoss, double takeProfit, double lotSize)
   {
      if(!isConnected)
      {
         if(logger)
            logger.LogEvent("BRIDGE", "ERROR", "Not connected. Cannot send signal");
         return false;
      }

      string payload = BuildTradeSignalPayload(strategyName, direction, entryPrice, stopLoss, takeProfit, lotSize);

      if(logger)
         logger.LogDebug("BRIDGE", "SEND_SIGNAL", "Sending signal: " + payload);

      return SendHTTPRequest("/trade/signal", "POST", payload);
   }

   bool SendMetrics(string strategyName, double equity, double balance, int openTrades, double dailyPnL)
   {
      if(!isConnected)
         return false;

      string payload = BuildMetricsPayload(strategyName, equity, balance, openTrades, dailyPnL);

      return SendHTTPRequest("/metrics", "POST", payload);
   }

   string ReceiveCommand()
   {
      if(!isConnected)
         return "";

      string response = "";
      if(SendHTTPRequest("/command", "GET", ""))
      {
         return response;
      }

      return "";
   }
   
   // Enviar resposta de comando
   bool SendCommandResponse(string commandId, string status, string result = "")
   {
      if(!isConnected)
      {
         if(logger)
            logger.LogEvent("BRIDGE", "ERROR", "Not connected. Cannot send command response");
         return false;
      }

      string payload = BuildCommandResponsePayload(commandId, status, result);

      if(logger)
         logger.LogDebug("BRIDGE", "SEND_RESPONSE", "Sending command response: " + payload);

      return SendHTTPRequest("/commands/response", "POST", payload);
   }

   // Construir payload de resposta
   string BuildCommandResponsePayload(string commandId, string status, string result)
   {
      string payload = "{";
      payload += "\"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\", ";
      payload += "\"command_id\": \"" + commandId + "\", ";
      payload += "\"status\": \"" + status + "\", ";
      payload += "\"result\": \"" + result + "\", ";
      payload += "\"account_number\": " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
      payload += "}";
      return payload;
   }   
   

private:
   bool TestConnection()
   {
      uchar postData[];
      uchar responseBody[];
      string responseHeaders = "";

      string testPayload = "{\"test\": true}";
      StringToCharArray(testPayload, postData);

      int res = WebRequest("POST", serverUrl + "/health", "", 5000, postData, responseBody, responseHeaders);

      return (res == 200);
   }

   bool SendHTTPRequest(string endpoint, string method, string payload)
   {
      uchar postData[];
      if(payload != "")
         StringToCharArray(payload, postData);

      uchar responseBody[];
      string responseHeaders = "";
      int timeout = 5000;

      string fullUrl = serverUrl + endpoint;

      int res = WebRequest(method, fullUrl, "", timeout, postData, responseBody, responseHeaders);

      if(res == -1)
      {
         if(logger)
            logger.LogEvent("BRIDGE", "HTTP_ERROR", "WebRequest failed: " + IntegerToString(GetLastError()));
         return false;
      }
      else if(res != 200)
      {
         if(logger)
            logger.LogEvent("BRIDGE", "HTTP_ERROR", "Server returned: " + IntegerToString(res));
         return false;
      }

      return true;
   }

   string BuildTradeSignalPayload(string strategyName, string direction, double entryPrice, double stopLoss, double takeProfit, double lotSize)
   {
      string payload = "{";
      payload += "\"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\", ";
      payload += "\"strategy\": \"" + strategyName + "\", ";
      payload += "\"direction\": \"" + direction + "\", ";
      payload += "\"entryPrice\": " + DoubleToString(entryPrice, 5) + ", ";
      payload += "\"stopLoss\": " + DoubleToString(stopLoss, 5) + ", ";
      payload += "\"takeProfit\": " + DoubleToString(takeProfit, 5) + ", ";
      payload += "\"lotSize\": " + DoubleToString(lotSize, 2);
      payload += "}";

      return payload;
   }

   string BuildMetricsPayload(string strategyName, double equity, double balance, int openTrades, double dailyPnL)
   {
      string payload = "{";
      payload += "\"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\", ";
      payload += "\"strategy\": \"" + strategyName + "\", ";
      payload += "\"equity\": " + DoubleToString(equity, 2) + ", ";
      payload += "\"balance\": " + DoubleToString(balance, 2) + ", ";
      payload += "\"openTrades\": " + IntegerToString(openTrades) + ", ";
      payload += "\"dailyPnL\": " + DoubleToString(dailyPnL, 2);
      payload += "}";

      return payload;
   }
};

#endif