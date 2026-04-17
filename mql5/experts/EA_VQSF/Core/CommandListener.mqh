#ifndef __COMMAND_LISTENER_MQH__
#define __COMMAND_LISTENER_MQH__

#include "Logger.mqh"
#include "Types.mqh"

// Enum para tipos de comando
enum COMMAND_TYPE
{
   CMD_START_STRATEGY = 1,
   CMD_STOP_STRATEGY = 2,
   CMD_CLOSE_ALL_TRADES = 3,
   CMD_ADJUST_PARAMETER = 4,
   CMD_SET_DAILY_LIMIT = 5,
   CMD_PAUSE_TRADING = 6,
   CMD_UPDATE_TRAILING_STOP = 7,
   CMD_GET_CONFIG = 8,
   CMD_UNKNOWN = 0
};

// Estrutura para armazenar comando
struct CommandData
{
   COMMAND_TYPE type;
   string commandId;
   string strategy;
   string paramName;
   double paramValue;
   int pauseMinutes;
   double dailyProfitLimit;
   double dailyLossLimit;
   double trailingPercent;
   datetime receivedAt;
};

class CCommandListener
{
private:
   string serverUrl;
   CLogger* logger;
   bool isListening;
   CommandData lastCommand;
   int pollIntervalMs;

public:
   CCommandListener()
   {
      serverUrl = "http://localhost:5000/commands";
      logger = NULL;
      isListening = false;
      pollIntervalMs = 5000;
      ZeroMemory(lastCommand);
   }

   ~CCommandListener()
   {
   }

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   void SetServerUrl(string url)
   {
      serverUrl = url;
   }

   void SetPollInterval(int ms)
   {
      pollIntervalMs = ms;
   }

   void Start()
   {
      isListening = true;
      if(logger)
         logger.LogEvent("COMMAND_LISTENER", "START", "Command listener started - Poll interval: " + IntegerToString(pollIntervalMs) + "ms");
   }

   void Stop()
   {
      isListening = false;
      if(logger)
         logger.LogEvent("COMMAND_LISTENER", "STOP", "Command listener stopped");
   }

   // Verifica e retorna comando pendente (não-bloqueante)
   bool CheckForCommand(CommandData &outCommand)
   {
      if(!isListening)
         return false;

      // Fazer request HTTP ao servidor
      string response = FetchCommandFromServer();

      if(response == "")
         return false;

      // Parsear resposta JSON
      if(ParseCommand(response, outCommand))
      {
         lastCommand = outCommand;

         if(logger)
            logger.LogEvent("COMMAND_LISTENER", "RECEIVED",
               "Command " + IntegerToString((int)outCommand.type) +
               " for strategy: " + outCommand.strategy);

         return true;
      }

      return false;
   }

   // Retorna último comando recebido
   CommandData GetLastCommand()
   {
      return lastCommand;
   }

private:

   string FetchCommandFromServer()
   {
      uchar postData[];
      uchar responseBody[];
      string responseHeaders = "";

      int res = WebRequest("GET", serverUrl, "", 5000, postData, responseBody, responseHeaders);

      if(res != 200)
         return "";

      string response = CharArrayToString(responseBody);
      return response;
   }

   bool ParseCommand(string jsonResponse, CommandData &outCommand)
   {
      // ✅ Parser JSON simplificado

      ZeroMemory(outCommand);
      outCommand.receivedAt = TimeCurrent();

      // Extrair type
      int typePos = StringFind(jsonResponse, "\"type\":");
      if(typePos < 0)
         return false;

      string typeStr = ExtractJsonValue(jsonResponse, "type");
      outCommand.type = (COMMAND_TYPE)StringToInteger(typeStr);

      // Extrair command_id
      outCommand.commandId = ExtractJsonValue(jsonResponse, "command_id");

      // Extrair strategy
      outCommand.strategy = ExtractJsonValue(jsonResponse, "strategy");

      // Extrair payload conforme tipo de comando
      switch(outCommand.type)
      {
         case CMD_START_STRATEGY:
         case CMD_STOP_STRATEGY:
         case CMD_CLOSE_ALL_TRADES:
            // Sem parâmetros adicionais
            break;

         case CMD_ADJUST_PARAMETER:
            outCommand.paramName = ExtractJsonValue(jsonResponse, "param_name");
            outCommand.paramValue = StringToDouble(ExtractJsonValue(jsonResponse, "param_value"));
            break;

         case CMD_SET_DAILY_LIMIT:
            outCommand.dailyProfitLimit = StringToDouble(ExtractJsonValue(jsonResponse, "daily_profit_limit"));
            outCommand.dailyLossLimit = StringToDouble(ExtractJsonValue(jsonResponse, "daily_loss_limit"));
            break;

         case CMD_PAUSE_TRADING:
            outCommand.pauseMinutes = (int)StringToInteger(ExtractJsonValue(jsonResponse, "pause_minutes"));
            break;

         case CMD_UPDATE_TRAILING_STOP:
            outCommand.trailingPercent = StringToDouble(ExtractJsonValue(jsonResponse, "trailing_percent"));
            break;

         case CMD_GET_CONFIG:
            // Sem parâmetros adicionais
            break;

         default:
            return false;
      }

      return true;
   }

   // Extrai valor de uma chave JSON
   string ExtractJsonValue(string json, string key)
   {
      string searchKey = "\"" + key + "\":";
      int startPos = StringFind(json, searchKey);

      if(startPos < 0)
         return "";

      startPos += StringLen(searchKey);

      // Pular espaços
      while(startPos < StringLen(json) && (json[startPos] == ' ' || json[startPos] == '\t'))
         startPos++;

      // Extrair valor (string ou número)
      string value = "";
      bool isString = (json[startPos] == '"');

      if(isString)
      {
         startPos++; // Pular aspas iniciais
         while(startPos < StringLen(json) && json[startPos] != '"')
         {
            // ✅ CORRIGIDO: Cast ushort para char antes de concatenar
            value += CharToString((uchar)json[startPos]);
            startPos++;
         }
      }
      else
      {
         while(startPos < StringLen(json) && json[startPos] != ',' && json[startPos] != '}' && json[startPos] != ']')
         {
            // ✅ CORRIGIDO: Cast ushort para char antes de concatenar
            value += CharToString((uchar)json[startPos]);
            startPos++;
         }
      }

      return value;
   }

};

#endif