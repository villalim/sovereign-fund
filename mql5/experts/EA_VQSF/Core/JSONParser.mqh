#ifndef __JSON_PARSER_MQH__
#define __JSON_PARSER_MQH__

#include "Types.mqh"
#include "Logger.mqh"
#include "BaseConfig.mqh"
#include "MemoryBuffer.mqh"

class CJSONParser
{
private:
   string filePath;
   CLogger* logger;
   CMemoryBuffer jsonCache;
   bool cacheValid;
   datetime lastLoadTime;

public:
   CJSONParser()
   {
      filePath = "strategies_config.json";
      logger = NULL;
      cacheValid = false;
      lastLoadTime = 0;
   }

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   void SetFilePath(string path)
   {
      filePath = path;
      cacheValid = false;
   }

   bool FileExists()
   {
      int file = FileOpen(filePath, FILE_READ | FILE_TXT);
      if(file == INVALID_HANDLE)
         return false;

      FileClose(file);
      return true;
   }

   bool CreateDefaultFile()
   {
      int file = FileOpen(filePath, FILE_WRITE | FILE_TXT);
      if(file == INVALID_HANDLE)
      {
         if(logger)
            logger.LogEvent("JSON_PARSER", "ERROR", "Failed to create file: " + filePath);
         return false;
      }

      string json = BuildDefaultJSON();
      FileWriteString(file, json);
      FileClose(file);

      if(logger)
         logger.LogEvent("JSON_PARSER", "CREATE", "Default config file created: " + filePath);

      cacheValid = false;
      return true;
   }

   string BuildDefaultJSON()
   {
      string json = "{\n";
      json += "  \"3BullGoDown\": {\n";
      json += "    \"Enabled\": true,\n";
      json += "    \"StartHour\": 9,\n";
      json += "    \"StartMinute\": 0,\n";
      json += "    \"EndHour\": 17,\n";
      json += "    \"EndMinute\": 0,\n";
      json += "    \"NewsFilterPauseMinutes\": 0,\n";
      json += "    \"NewsFilterCloseMinutes\": 0,\n";
      json += "    \"MagicNumber\": 10003,\n";
      json += "    \"LotSize\": 0.75,\n";
      json += "    \"StopLossPoints\": 200,\n";
      json += "    \"MinSequence\": 3,\n";
      json += "    \"MinCandleSize\": 50,\n";
      json += "    \"MaxCandleSize\": 500,\n";
      json += "    \"MinTakeProfit\": 100,\n";
      json += "    \"MaxTakeProfit\": 500,\n";
      json += "    \"LongSequenceMultiplier\": 2.0\n";
      json += "  },\n";

      json += "  \"3BearGoDown\": {\n";
      json += "    \"Enabled\": true,\n";
      json += "    \"StartHour\": 9,\n";
      json += "    \"StartMinute\": 0,\n";
      json += "    \"EndHour\": 17,\n";
      json += "    \"EndMinute\": 0,\n";
      json += "    \"NewsFilterPauseMinutes\": 0,\n";
      json += "    \"NewsFilterCloseMinutes\": 0,\n";
      json += "    \"MagicNumber\": 10001,\n";
      json += "    \"LotSize\": 0.75,\n";
      json += "    \"StopLossPoints\": 300,\n";
      json += "    \"MinSequence\": 3,\n";
      json += "    \"MinCandleSize\": 50,\n";
      json += "    \"MaxCandleSize\": 500,\n";
      json += "    \"MinTakeProfit\": 150,\n";
      json += "    \"MaxTakeProfit\": 750,\n";
      json += "    \"LongSequenceMultiplier\": 2.0,\n";
      json += "    \"TrendValidationBars\": 20\n";
      json += "  },\n";

      json += "  \"2Bear2BullGoUp\": {\n";
      json += "    \"Enabled\": true,\n";
      json += "    \"StartHour\": 9,\n";
      json += "    \"StartMinute\": 0,\n";
      json += "    \"EndHour\": 17,\n";
      json += "    \"EndMinute\": 0,\n";
      json += "    \"NewsFilterPauseMinutes\": 0,\n";
      json += "    \"NewsFilterCloseMinutes\": 0,\n";
      json += "    \"MagicNumber\": 10002,\n";
      json += "    \"LotSize\": 0.75,\n";
      json += "    \"StopLossPoints\": 200,\n";
      json += "    \"MinSequence\": 4,\n";
      json += "    \"MinCandleSize\": 50,\n";
      json += "    \"MaxCandleSize\": 500,\n";
      json += "    \"MinTakeProfit\": 100,\n";
      json += "    \"MaxTakeProfit\": 500,\n";
      json += "    \"LongSequenceMultiplier\": 2.0\n";
      json += "  }\n";

      json += "}\n";

      return json;
   }

   bool LoadConfig(string strategyName, CBaseConfig &config)
   {
      if(!FileExists())
      {
         if(!CreateDefaultFile())
            return false;
      }

      string jsonContent = LoadJSONFromFile();
      if(jsonContent == "")
         return false;

      return ParseAndLoadConfig(jsonContent, strategyName, config);
   }

   string LoadJSONFromFile()
   {
      int file = FileOpen(filePath, FILE_READ | FILE_TXT);
      if(file == INVALID_HANDLE)
      {
         if(logger)
            logger.LogEvent("JSON_PARSER", "ERROR", "Failed to open file: " + filePath);
         return "";
      }

      string jsonContent = "";
      while(!FileIsEnding(file))
      {
         jsonContent += FileReadString(file);
      }
      FileClose(file);

      cacheValid = true;
      lastLoadTime = TimeCurrent();

      return jsonContent;
   }

   bool ParseAndLoadConfig(string jsonContent, string strategyName, CBaseConfig &config)
   {
      int strategyStart = StringFind(jsonContent, "\"" + strategyName + "\"");
      if(strategyStart == -1)
      {
         if(logger)
            logger.LogEvent("JSON_PARSER", "ERROR", "Strategy not found: " + strategyName);
         return false;
      }

      int braceCount = 0;
      int strategyEnd = strategyStart;
      bool inStrategy = false;

      for(int i = strategyStart; i < StringLen(jsonContent); i++)
      {
         ushort ch = StringGetCharacter(jsonContent, i);
         if(ch == '{')
         {
            braceCount++;
            inStrategy = true;
         }
         else if(ch == '}')
         {
            braceCount--;
            if(inStrategy && braceCount == 0)
            {
               strategyEnd = i + 1;
               break;
            }
         }
      }

      string strategyJson = StringSubstr(jsonContent, strategyStart, strategyEnd - strategyStart);

      config.Enabled = ParseBoolValue(strategyJson, "Enabled");
      config.StartHour = ParseIntValue(strategyJson, "StartHour");
      config.StartMinute = ParseIntValue(strategyJson, "StartMinute");
      config.EndHour = ParseIntValue(strategyJson, "EndHour");
      config.EndMinute = ParseIntValue(strategyJson, "EndMinute");
      config.NewsFilterPauseMinutes = ParseIntValue(strategyJson, "NewsFilterPauseMinutes");
      config.NewsFilterCloseMinutes = ParseIntValue(strategyJson, "NewsFilterCloseMinutes");
      config.MagicNumber = ParseIntValue(strategyJson, "MagicNumber");
      config.LotSize = ParseDoubleValue(strategyJson, "LotSize");
      config.StopLossPoints = ParseIntValue(strategyJson, "StopLossPoints");
      config.MinSequence = ParseIntValue(strategyJson, "MinSequence");
      config.MinCandleSize = ParseDoubleValue(strategyJson, "MinCandleSize");
      config.MaxCandleSize = ParseDoubleValue(strategyJson, "MaxCandleSize");
      config.MinTakeProfit = ParseDoubleValue(strategyJson, "MinTakeProfit");
      config.MaxTakeProfit = ParseDoubleValue(strategyJson, "MaxTakeProfit");
      config.LongSequenceMultiplier = ParseDoubleValue(strategyJson, "LongSequenceMultiplier");
      config.TrendValidationBars = ParseIntValue(strategyJson, "TrendValidationBars");

      if(logger)
         logger.LogEvent("JSON_PARSER", "LOAD", "Loaded config for: " + strategyName);

      return true;
   }

   int ParseIntValue(string json, string key)
   {
      int keyPos = StringFind(json, "\"" + key + "\"");
      if(keyPos == -1)
         return 0;

      int colonPos = StringFind(json, ":", keyPos);
      if(colonPos == -1)
         return 0;

      int valueStart = colonPos + 1;
      while(valueStart < StringLen(json))
      {
         ushort ch = StringGetCharacter(json, valueStart);
         if(ch != ' ' && ch != '\t')
            break;
         valueStart++;
      }

      int valueEnd = valueStart;
      while(valueEnd < StringLen(json))
      {
         ushort ch = StringGetCharacter(json, valueEnd);
         if(ch < '0' || ch > '9')
            break;
         valueEnd++;
      }

      if(valueStart >= valueEnd)
         return 0;

      string valueStr = StringSubstr(json, valueStart, valueEnd - valueStart);
      return (int)StringToInteger(valueStr);
   }

   double ParseDoubleValue(string json, string key)
   {
      int keyPos = StringFind(json, "\"" + key + "\"");
      if(keyPos == -1)
         return 0.0;

      int colonPos = StringFind(json, ":", keyPos);
      if(colonPos == -1)
         return 0.0;

      int valueStart = colonPos + 1;
      while(valueStart < StringLen(json))
      {
         ushort ch = StringGetCharacter(json, valueStart);
         if(ch != ' ' && ch != '\t')
            break;
         valueStart++;
      }

      int valueEnd = valueStart;
      while(valueEnd < StringLen(json))
      {
         ushort ch = StringGetCharacter(json, valueEnd);
         if((ch < '0' || ch > '9') && ch != '.')
            break;
         valueEnd++;
      }

      if(valueStart >= valueEnd)
         return 0.0;

      string valueStr = StringSubstr(json, valueStart, valueEnd - valueStart);
      return StringToDouble(valueStr);
   }

   bool ParseBoolValue(string json, string key)
   {
      int keyPos = StringFind(json, "\"" + key + "\"");
      if(keyPos == -1)
         return false;

      int colonPos = StringFind(json, ":", keyPos);
      if(colonPos == -1)
         return false;

      int valueStart = colonPos + 1;
      while(valueStart < StringLen(json))
      {
         ushort ch = StringGetCharacter(json, valueStart);
         if(ch != ' ' && ch != '\t')
            break;
         valueStart++;
      }

      string remaining = StringSubstr(json, valueStart);

      if(StringFind(remaining, "true") == 0)
         return true;
      else if(StringFind(remaining, "false") == 0)
         return false;

      return false;
   }

   bool SaveConfig(string strategyName, CBaseConfig &config)
   {
      if(!FileExists())
      {
         if(!CreateDefaultFile())
            return false;
      }

      int file = FileOpen(filePath, FILE_READ | FILE_TXT);
      if(file == INVALID_HANDLE)
         return false;

      string jsonContent = "";
      while(!FileIsEnding(file))
      {
         jsonContent += FileReadString(file);
      }
      FileClose(file);

      jsonContent = UpdateStrategyInJSON(jsonContent, strategyName, config);

      file = FileOpen(filePath, FILE_WRITE | FILE_TXT);
      if(file == INVALID_HANDLE)
      {
         if(logger)
            logger.LogEvent("JSON_PARSER", "ERROR", "Failed to write file: " + filePath);
         return false;
      }

      FileWriteString(file, jsonContent);
      FileClose(file);

      if(logger)
         logger.LogEvent("JSON_PARSER", "SAVE", "Saved config for: " + strategyName);

      cacheValid = false;
      return true;
   }

   string UpdateStrategyInJSON(string jsonContent, string strategyName, CBaseConfig &config)
   {
      int strategyStart = StringFind(jsonContent, "\"" + strategyName + "\"");
      if(strategyStart == -1)
         return jsonContent;

      int braceCount = 0;
      int strategyEnd = strategyStart;
      bool inStrategy = false;

      for(int i = strategyStart; i < StringLen(jsonContent); i++)
      {
         ushort ch = StringGetCharacter(jsonContent, i);
         if(ch == '{')
         {
            braceCount++;
            inStrategy = true;
         }
         else if(ch == '}')
         {
            braceCount--;
            if(inStrategy && braceCount == 0)
            {
               strategyEnd = i + 1;
               break;
            }
         }
      }

      string newStrategy = BuildStrategyJSON(strategyName, config);

      string before = StringSubstr(jsonContent, 0, strategyStart);
      string after = StringSubstr(jsonContent, strategyEnd);

      return before + newStrategy + after;
   }

   string BuildStrategyJSON(string strategyName, CBaseConfig &config)
   {
      string json = "\"" + strategyName + "\": {\n";
      json += "    \"Enabled\": " + (config.Enabled ? "true" : "false") + ",\n";
      json += "    \"StartHour\": " + IntegerToString(config.StartHour) + ",\n";
      json += "    \"StartMinute\": " + IntegerToString(config.StartMinute) + ",\n";
      json += "    \"EndHour\": " + IntegerToString(config.EndHour) + ",\n";
      json += "    \"EndMinute\": " + IntegerToString(config.EndMinute) + ",\n";
      json += "    \"NewsFilterPauseMinutes\": " + IntegerToString(config.NewsFilterPauseMinutes) + ",\n";
      json += "    \"NewsFilterCloseMinutes\": " + IntegerToString(config.NewsFilterCloseMinutes) + ",\n";
      json += "    \"MagicNumber\": " + IntegerToString(config.MagicNumber) + ",\n";
      json += "    \"LotSize\": " + DoubleToString(config.LotSize, 2) + ",\n";
      json += "    \"StopLossPoints\": " + IntegerToString(config.StopLossPoints) + ",\n";
      json += "    \"MinSequence\": " + IntegerToString(config.MinSequence) + ",\n";
      json += "    \"MinCandleSize\": " + DoubleToString(config.MinCandleSize, 0) + ",\n";
      json += "    \"MaxCandleSize\": " + DoubleToString(config.MaxCandleSize, 0) + ",\n";
      json += "    \"MinTakeProfit\": " + DoubleToString(config.MinTakeProfit, 0) + ",\n";
      json += "    \"MaxTakeProfit\": " + DoubleToString(config.MaxTakeProfit, 0) + ",\n";
      json += "    \"LongSequenceMultiplier\": " + DoubleToString(config.LongSequenceMultiplier, 2) + ",\n";
      json += "    \"TrendValidationBars\": " + IntegerToString(config.TrendValidationBars) + "\n";
      json += "  }";

      return json;
   }
};

#endif