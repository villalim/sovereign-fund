#ifndef __CONFIG_MANAGER_MQH__
#define __CONFIG_MANAGER_MQH__

#include "Types.mqh"
#include "BaseConfig.mqh"
#include "Logger.mqh"
#include "JSONParser.mqh"
#include "../Config/Config_3BullGoDown.mqh"
#include "../Config/Config_3BearGoDown.mqh"
#include "../Config/Config_2Bear2BullGoUP.mqh"

class CConfigManager
{
private:
   CConfig_3BullGoDown config3BullGoDown;
   CConfig_3BearGoDown config3BearGoDown;
   CConfig_2Bear2BullGoUP config2Bear2BullGoUp;
   CLogger* logger;
   string configFilePath;
   bool autoSyncEnabled;
public:
   CConfigManager()
   {
      logger = NULL;
      configFilePath = "strategies_config.json";
      autoSyncEnabled = true;
   }
   void SetLogger(CLogger* log)
   {
      logger = log;
   }
   void SetConfigFilePath(string filePath)
   {
      configFilePath = filePath;
   }
   void SetAutoSync(bool enabled)
   {
      autoSyncEnabled = enabled;
   }
   bool LoadFromFile()
   {
      CJSONParser parser;
      parser.SetLogger(logger);
      parser.SetFilePath(configFilePath);
      bool success = true;
      if(!parser.LoadConfig("3BullGoDown", config3BullGoDown))
      {
         if(logger)
            logger.LogEvent("CONFIG", "WARNING", "Failed to load 3BullGoDown config");
         success = false;
      }
      if(!parser.LoadConfig("3BearGoDown", config3BearGoDown))
      {
         if(logger)
            logger.LogEvent("CONFIG", "WARNING", "Failed to load 3BearGoDown config");
         success = false;
      }
      if(!parser.LoadConfig("2Bear2BullGoUp", config2Bear2BullGoUp))
      {
         if(logger)
            logger.LogEvent("CONFIG", "WARNING", "Failed to load 2Bear2BullGoUp config");
         success = false;
      }
      if(success)
      {
         if(logger)
            logger.LogEvent("CONFIG", "LOAD", "All configs loaded from file successfully");
      }
      return success;
   }
   bool SaveToFile()
   {
      CJSONParser parser;
      parser.SetLogger(logger);
      parser.SetFilePath(configFilePath);
      bool success = true;
      if(!parser.SaveConfig("3BullGoDown", config3BullGoDown))
      {
         if(logger)
            logger.LogEvent("CONFIG", "ERROR", "Failed to save 3BullGoDown config");
         success = false;
      }
      if(!parser.SaveConfig("3BearGoDown", config3BearGoDown))
      {
         if(logger)
            logger.LogEvent("CONFIG", "ERROR", "Failed to save 3BearGoDown config");
         success = false;
      }
      if(!parser.SaveConfig("2Bear2BullGoUp", config2Bear2BullGoUp))
      {
         if(logger)
            logger.LogEvent("CONFIG", "ERROR", "Failed to save 2Bear2BullGoUp config");
         success = false;
      }
      if(success)
      {
         if(logger)
            logger.LogEvent("CONFIG", "SAVE", "All configs saved to file successfully");
      }
      return success;
   }
   string BuildJSON()
   {
      string json = "{\n";
      json += "  \"3BullGoDown\": {\n";
      json += "    \"Enabled\": " + (config3BullGoDown.Enabled ? "true" : "false") + ",\n";
      json += "    \"StartHour\": " + IntegerToString(config3BullGoDown.StartHour) + ",\n";
      json += "    \"StartMinute\": " + IntegerToString(config3BullGoDown.StartMinute) + ",\n";
      json += "    \"EndHour\": " + IntegerToString(config3BullGoDown.EndHour) + ",\n";
      json += "    \"EndMinute\": " + IntegerToString(config3BullGoDown.EndMinute) + ",\n";
      json += "    \"NewsFilterPauseMinutes\": " + IntegerToString(config3BullGoDown.NewsFilterPauseMinutes) + ",\n";
      json += "    \"NewsFilterCloseMinutes\": " + IntegerToString(config3BullGoDown.NewsFilterCloseMinutes) + ",\n";
      json += "    \"MagicNumber\": " + IntegerToString(config3BullGoDown.MagicNumber) + ",\n";
      json += "    \"LotSize\": " + DoubleToString(config3BullGoDown.LotSize, 2) + ",\n";
      json += "    \"StopLossPoints\": " + IntegerToString(config3BullGoDown.StopLossPoints) + ",\n";
      json += "    \"MinSequence\": " + IntegerToString(config3BullGoDown.MinSequence) + ",\n";
      json += "    \"MinCandleSize\": " + DoubleToString(config3BullGoDown.MinCandleSize, 0) + ",\n";
      json += "    \"MaxCandleSize\": " + DoubleToString(config3BullGoDown.MaxCandleSize, 0) + ",\n";
      json += "    \"MinTakeProfit\": " + DoubleToString(config3BullGoDown.MinTakeProfit, 0) + ",\n";
      json += "    \"MaxTakeProfit\": " + DoubleToString(config3BullGoDown.MaxTakeProfit, 0) + ",\n";
      json += "    \"LongSequenceMultiplier\": " + DoubleToString(config3BullGoDown.LongSequenceMultiplier, 2) + ",\n";
      json += "    \"EnableTrailingStop\": " + (config3BullGoDown.EnableTrailingStop ? "true" : "false") + ",\n";
      json += "    \"TrailingStopActivationPercent\": " + DoubleToString(config3BullGoDown.TrailingStopActivationPercent, 2) + ",\n";
      json += "    \"LotCalculationType\": " + IntegerToString(config3BullGoDown.LotCalculationType) + ",\n";
      json += "    \"InitialDeposit\": " + DoubleToString(config3BullGoDown.InitialDeposit, 2) + ",\n";
      json += "    \"MaxRiskPerTrade\": " + DoubleToString(config3BullGoDown.MaxRiskPerTrade, 2) + "\n";
      json += "  },\n";
      json += "  \"3BearGoDown\": {\n";
      json += "    \"Enabled\": " + (config3BearGoDown.Enabled ? "true" : "false") + ",\n";
      json += "    \"StartHour\": " + IntegerToString(config3BearGoDown.StartHour) + ",\n";
      json += "    \"StartMinute\": " + IntegerToString(config3BearGoDown.StartMinute) + ",\n";
      json += "    \"EndHour\": " + IntegerToString(config3BearGoDown.EndHour) + ",\n";
      json += "    \"EndMinute\": " + IntegerToString(config3BearGoDown.EndMinute) + ",\n";
      json += "    \"NewsFilterPauseMinutes\": " + IntegerToString(config3BearGoDown.NewsFilterPauseMinutes) + ",\n";
      json += "    \"NewsFilterCloseMinutes\": " + IntegerToString(config3BearGoDown.NewsFilterCloseMinutes) + ",\n";
      json += "    \"MagicNumber\": " + IntegerToString(config3BearGoDown.MagicNumber) + ",\n";
      json += "    \"LotSize\": " + DoubleToString(config3BearGoDown.LotSize, 2) + ",\n";
      json += "    \"StopLossPoints\": " + IntegerToString(config3BearGoDown.StopLossPoints) + ",\n";
      json += "    \"MinSequence\": " + IntegerToString(config3BearGoDown.MinSequence) + ",\n";
      json += "    \"MinCandleSize\": " + DoubleToString(config3BearGoDown.MinCandleSize, 0) + ",\n";
      json += "    \"MaxCandleSize\": " + DoubleToString(config3BearGoDown.MaxCandleSize, 0) + ",\n";
      json += "    \"MinTakeProfit\": " + DoubleToString(config3BearGoDown.MinTakeProfit, 0) + ",\n";
      json += "    \"MaxTakeProfit\": " + DoubleToString(config3BearGoDown.MaxTakeProfit, 0) + ",\n";
      json += "    \"LongSequenceMultiplier\": " + DoubleToString(config3BearGoDown.LongSequenceMultiplier, 2) + ",\n";
      json += "    \"EnableTrailingStop\": " + (config3BearGoDown.EnableTrailingStop ? "true" : "false") + ",\n";
      json += "    \"TrailingStopActivationPercent\": " + DoubleToString(config3BearGoDown.TrailingStopActivationPercent, 2) + ",\n";
      json += "    \"LotCalculationType\": " + IntegerToString(config3BearGoDown.LotCalculationType) + ",\n";
      json += "    \"InitialDeposit\": " + DoubleToString(config3BearGoDown.InitialDeposit, 2) + ",\n";
      json += "    \"MaxRiskPerTrade\": " + DoubleToString(config3BearGoDown.MaxRiskPerTrade, 2) + "\n";
      json += "  },\n";
      json += "  \"2Bear2BullGoUp\": {\n";
      json += "    \"Enabled\": " + (config2Bear2BullGoUp.Enabled ? "true" : "false") + ",\n";
      json += "    \"StartHour\": " + IntegerToString(config2Bear2BullGoUp.StartHour) + ",\n";
      json += "    \"StartMinute\": " + IntegerToString(config2Bear2BullGoUp.StartMinute) + ",\n";
      json += "    \"EndHour\": " + IntegerToString(config2Bear2BullGoUp.EndHour) + ",\n";
      json += "    \"EndMinute\": " + IntegerToString(config2Bear2BullGoUp.EndMinute) + ",\n";
      json += "    \"NewsFilterPauseMinutes\": " + IntegerToString(config2Bear2BullGoUp.NewsFilterPauseMinutes) + ",\n";
      json += "    \"NewsFilterCloseMinutes\": " + IntegerToString(config2Bear2BullGoUp.NewsFilterCloseMinutes) + ",\n";
      json += "    \"MagicNumber\": " + IntegerToString(config2Bear2BullGoUp.MagicNumber) + ",\n";
      json += "    \"LotSize\": " + DoubleToString(config2Bear2BullGoUp.LotSize, 2) + ",\n";
      json += "    \"StopLossPoints\": " + IntegerToString(config2Bear2BullGoUp.StopLossPoints) + ",\n";
      json += "    \"MinSequence\": " + IntegerToString(config2Bear2BullGoUp.MinSequence) + ",\n";
      json += "    \"MinCandleSize\": " + DoubleToString(config2Bear2BullGoUp.MinCandleSize, 0) + ",\n";
      json += "    \"MaxCandleSize\": " + DoubleToString(config2Bear2BullGoUp.MaxCandleSize, 0) + ",\n";
      json += "    \"MinTakeProfit\": " + DoubleToString(config2Bear2BullGoUp.MinTakeProfit, 0) + ",\n";
      json += "    \"MaxTakeProfit\": " + DoubleToString(config2Bear2BullGoUp.MaxTakeProfit, 0) + ",\n";
      json += "    \"LongSequenceMultiplier\": " + DoubleToString(config2Bear2BullGoUp.LongSequenceMultiplier, 2) + ",\n";
      json += "    \"EnableTrailingStop\": " + (config2Bear2BullGoUp.EnableTrailingStop ? "true" : "false") + ",\n";
      json += "    \"TrailingStopActivationPercent\": " + DoubleToString(config2Bear2BullGoUp.TrailingStopActivationPercent, 2) + ",\n";
      json += "    \"LotCalculationType\": " + IntegerToString(config2Bear2BullGoUp.LotCalculationType) + ",\n";
      json += "    \"InitialDeposit\": " + DoubleToString(config2Bear2BullGoUp.InitialDeposit, 2) + ",\n";
      json += "    \"MaxRiskPerTrade\": " + DoubleToString(config2Bear2BullGoUp.MaxRiskPerTrade, 2) + "\n";
      json += "  }\n";
      json += "}\n";
      return json;
   }
   void SyncInputsToConfigs(bool inp3BullGoDown_Enabled, int inp3BullGoDown_StartHour, int inp3BullGoDown_StartMinute,
      int inp3BullGoDown_EndHour, int inp3BullGoDown_EndMinute, int inp3BullGoDown_NewsFilterPauseMinutes,
      int inp3BullGoDown_NewsFilterCloseMinutes, int inp3BullGoDown_MagicNumber, double inp3BullGoDown_LotSize,
      int inp3BullGoDown_StopLoss, int inp3BullGoDown_MinSequence, double inp3BullGoDown_MinCandleSize,
      double inp3BullGoDown_MaxCandleSize, double inp3BullGoDown_MinTakeProfit, double inp3BullGoDown_MaxTakeProfit,
      double inp3BullGoDown_LongSequenceMultiplier, bool inp3BullGoDown_EnableTrailingStop,
      double inp3BullGoDown_TrailingStopActivationPercent, int inp3BullGoDown_LotCalculationType,
      double inp3BullGoDown_InitialDeposit, double inp3BullGoDown_MaxRiskPerTrade,
      bool inp3BearGoDown_Enabled, int inp3BearGoDown_StartHour, int inp3BearGoDown_StartMinute,
      int inp3BearGoDown_EndHour, int inp3BearGoDown_EndMinute, int inp3BearGoDown_NewsFilterPauseMinutes,
      int inp3BearGoDown_NewsFilterCloseMinutes, int inp3BearGoDown_MagicNumber, double inp3BearGoDown_LotSize,
      int inp3BearGoDown_StopLoss, int inp3BearGoDown_MinSequence, double inp3BearGoDown_MinCandleSize,
      double inp3BearGoDown_MaxCandleSize, double inp3BearGoDown_MinTakeProfit, double inp3BearGoDown_MaxTakeProfit,
      double inp3BearGoDown_LongSequenceMultiplier, bool inp3BearGoDown_EnableTrailingStop,
      double inp3BearGoDown_TrailingStopActivationPercent, int inp3BearGoDown_LotCalculationType,
      double inp3BearGoDown_InitialDeposit, double inp3BearGoDown_MaxRiskPerTrade,
      bool inp2Bear2BullGoUp_Enabled, int inp2Bear2BullGoUp_StartHour, int inp2Bear2BullGoUp_StartMinute,
      int inp2Bear2BullGoUp_EndHour, int inp2Bear2BullGoUp_EndMinute, int inp2Bear2BullGoUp_NewsFilterPauseMinutes,
      int inp2Bear2BullGoUp_NewsFilterCloseMinutes, int inp2Bear2BullGoUp_MagicNumber, double inp2Bear2BullGoUp_LotSize,
      int inp2Bear2BullGoUp_StopLoss, int inp2Bear2BullGoUp_MinSequence, double inp2Bear2BullGoUp_MinCandleSize,
      double inp2Bear2BullGoUp_MaxCandleSize, double inp2Bear2BullGoUp_MinTakeProfit, double inp2Bear2BullGoUp_MaxTakeProfit,
      double inp2Bear2BullGoUp_LongSequenceMultiplier, bool inp2Bear2BullGoUp_EnableTrailingStop,
      double inp2Bear2BullGoUp_TrailingStopActivationPercent, int inp2Bear2BullGoUp_LotCalculationType,
      double inp2Bear2BullGoUp_InitialDeposit, double inp2Bear2BullGoUp_MaxRiskPerTrade)
   {
      config3BullGoDown.Enabled = inp3BullGoDown_Enabled;
      config3BullGoDown.StartHour = inp3BullGoDown_StartHour;
      config3BullGoDown.StartMinute = inp3BullGoDown_StartMinute;
      config3BullGoDown.EndHour = inp3BullGoDown_EndHour;
      config3BullGoDown.EndMinute = inp3BullGoDown_EndMinute;
      config3BullGoDown.NewsFilterPauseMinutes = inp3BullGoDown_NewsFilterPauseMinutes;
      config3BullGoDown.NewsFilterCloseMinutes = inp3BullGoDown_NewsFilterCloseMinutes;
      config3BullGoDown.MagicNumber = inp3BullGoDown_MagicNumber;
      config3BullGoDown.LotSize = inp3BullGoDown_LotSize;
      config3BullGoDown.StopLossPoints = inp3BullGoDown_StopLoss;
      config3BullGoDown.MinSequence = inp3BullGoDown_MinSequence;
      config3BullGoDown.MinCandleSize = inp3BullGoDown_MinCandleSize;
      config3BullGoDown.MaxCandleSize = inp3BullGoDown_MaxCandleSize;
      config3BullGoDown.MinTakeProfit = inp3BullGoDown_MinTakeProfit;
      config3BullGoDown.MaxTakeProfit = inp3BullGoDown_MaxTakeProfit;
      config3BullGoDown.LongSequenceMultiplier = inp3BullGoDown_LongSequenceMultiplier;
      config3BullGoDown.EnableTrailingStop = inp3BullGoDown_EnableTrailingStop;
      config3BullGoDown.TrailingStopActivationPercent = inp3BullGoDown_TrailingStopActivationPercent;
      config3BullGoDown.LotCalculationType = inp3BullGoDown_LotCalculationType;
      config3BullGoDown.InitialDeposit = inp3BullGoDown_InitialDeposit;
      config3BullGoDown.MaxRiskPerTrade = inp3BullGoDown_MaxRiskPerTrade;
      config3BearGoDown.Enabled = inp3BearGoDown_Enabled;
      config3BearGoDown.StartHour = inp3BearGoDown_StartHour;
      config3BearGoDown.StartMinute = inp3BearGoDown_StartMinute;
      config3BearGoDown.EndHour = inp3BearGoDown_EndHour;
      config3BearGoDown.EndMinute = inp3BearGoDown_EndMinute;
      config3BearGoDown.NewsFilterPauseMinutes = inp3BearGoDown_NewsFilterPauseMinutes;
      config3BearGoDown.NewsFilterCloseMinutes = inp3BearGoDown_NewsFilterCloseMinutes;
      config3BearGoDown.MagicNumber = inp3BearGoDown_MagicNumber;
      config3BearGoDown.LotSize = inp3BearGoDown_LotSize;
      config3BearGoDown.StopLossPoints = inp3BearGoDown_StopLoss;
      config3BearGoDown.MinSequence = inp3BearGoDown_MinSequence;
      config3BearGoDown.MinCandleSize = inp3BearGoDown_MinCandleSize;
      config3BearGoDown.MaxCandleSize = inp3BearGoDown_MaxCandleSize;
      config3BearGoDown.MinTakeProfit = inp3BearGoDown_MinTakeProfit;
      config3BearGoDown.MaxTakeProfit = inp3BearGoDown_MaxTakeProfit;
      config3BearGoDown.LongSequenceMultiplier = inp3BearGoDown_LongSequenceMultiplier;
      config3BearGoDown.EnableTrailingStop = inp3BearGoDown_EnableTrailingStop;
      config3BearGoDown.TrailingStopActivationPercent = inp3BearGoDown_TrailingStopActivationPercent;
      config3BearGoDown.LotCalculationType = inp3BearGoDown_LotCalculationType;
      config3BearGoDown.InitialDeposit = inp3BearGoDown_InitialDeposit;
      config3BearGoDown.MaxRiskPerTrade = inp3BearGoDown_MaxRiskPerTrade;
      config2Bear2BullGoUp.Enabled = inp2Bear2BullGoUp_Enabled;
      config2Bear2BullGoUp.StartHour = inp2Bear2BullGoUp_StartHour;
      config2Bear2BullGoUp.StartMinute = inp2Bear2BullGoUp_StartMinute;
      config2Bear2BullGoUp.EndHour = inp2Bear2BullGoUp_EndHour;
      config2Bear2BullGoUp.EndMinute = inp2Bear2BullGoUp_EndMinute;
      config2Bear2BullGoUp.NewsFilterPauseMinutes = inp2Bear2BullGoUp_NewsFilterPauseMinutes;
      config2Bear2BullGoUp.NewsFilterCloseMinutes = inp2Bear2BullGoUp_NewsFilterCloseMinutes;
      config2Bear2BullGoUp.MagicNumber = inp2Bear2BullGoUp_MagicNumber;
      config2Bear2BullGoUp.LotSize = inp2Bear2BullGoUp_LotSize;
      config2Bear2BullGoUp.StopLossPoints = inp2Bear2BullGoUp_StopLoss;
      config2Bear2BullGoUp.MinSequence = inp2Bear2BullGoUp_MinSequence;
      config2Bear2BullGoUp.MinCandleSize = inp2Bear2BullGoUp_MinCandleSize;
      config2Bear2BullGoUp.MaxCandleSize = inp2Bear2BullGoUp_MaxCandleSize;
      config2Bear2BullGoUp.MinTakeProfit = inp2Bear2BullGoUp_MinTakeProfit;
      config2Bear2BullGoUp.MaxTakeProfit = inp2Bear2BullGoUp_MaxTakeProfit;
      config2Bear2BullGoUp.LongSequenceMultiplier = inp2Bear2BullGoUp_LongSequenceMultiplier;
      config2Bear2BullGoUp.EnableTrailingStop = inp2Bear2BullGoUp_EnableTrailingStop;
      config2Bear2BullGoUp.TrailingStopActivationPercent = inp2Bear2BullGoUp_TrailingStopActivationPercent;
      config2Bear2BullGoUp.LotCalculationType = inp2Bear2BullGoUp_LotCalculationType;
      config2Bear2BullGoUp.InitialDeposit = inp2Bear2BullGoUp_InitialDeposit;
      config2Bear2BullGoUp.MaxRiskPerTrade = inp2Bear2BullGoUp_MaxRiskPerTrade;
      if(logger)
         logger.LogEvent("CONFIG", "SYNC", "Inputs synchronized to configs");
      if(autoSyncEnabled)
         SaveToFile();
   }
   bool SetParameter(string strategyName, string paramName, double value)
   {
      if(strategyName == "3BullGoDown")
         return SetParameterInternal(config3BullGoDown, paramName, value);
      else if(strategyName == "3BearGoDown")
         return SetParameterInternal(config3BearGoDown, paramName, value);
      else if(strategyName == "2Bear2BullGoUp")
         return SetParameterInternal(config2Bear2BullGoUp, paramName, value);
      if(logger)
         logger.LogEvent("CONFIG", "ERROR", "Unknown strategy: " + strategyName);
      return false;
   }
   bool SetParameterInternal(CBaseConfig &config, string paramName, double value)
   {
      if(paramName == "LotSize")
      {
         if(value <= 0 || value > 10)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid LotSize: " + DoubleToString(value, 2));
            return false;
         }
         config.LotSize = value;
      }
      else if(paramName == "StopLossPoints")
      {
         if(value <= 0 || value > 1000)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid StopLossPoints: " + DoubleToString(value, 0));
            return false;
         }
         config.StopLossPoints = (int)value;
      }
      else if(paramName == "MinSequence")
      {
         if(value <= 0 || value > 10)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid MinSequence: " + DoubleToString(value, 0));
            return false;
         }
         config.MinSequence = (int)value;
      }
      else if(paramName == "MinCandleSize")
      {
         if(value <= 0 || value > 1000)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid MinCandleSize: " + DoubleToString(value, 0));
            return false;
         }
         config.MinCandleSize = value;
      }
      else if(paramName == "MaxCandleSize")
      {
         if(value <= config.MinCandleSize || value > 2000)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid MaxCandleSize: " + DoubleToString(value, 0));
            return false;
         }
         config.MaxCandleSize = value;
      }
      else if(paramName == "MinTakeProfit")
      {
         if(value <= 0 || value > 1000)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid MinTakeProfit: " + DoubleToString(value, 0));
            return false;
         }
         config.MinTakeProfit = value;
      }
      else if(paramName == "MaxTakeProfit")
      {
         if(value <= config.MinTakeProfit || value > 2000)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid MaxTakeProfit: " + DoubleToString(value, 0));
            return false;
         }
         config.MaxTakeProfit = value;
      }
      else if(paramName == "LongSequenceMultiplier")
      {
         if(value <= 1.0 || value > 5.0)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid LongSequenceMultiplier: " + DoubleToString(value, 2));
            return false;
         }
         config.LongSequenceMultiplier = value;
      }
      else if(paramName == "LotCalculationType")
      {
         if(value < 0 || value > 1)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid LotCalculationType: " + DoubleToString(value, 0));
            return false;
         }
         config.LotCalculationType = (int)value;
      }
      else if(paramName == "InitialDeposit")
      {
         if(value <= 0)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid InitialDeposit: " + DoubleToString(value, 2));
            return false;
         }
         config.InitialDeposit = value;
      }
      else if(paramName == "MaxRiskPerTrade")
      {
         if(value <= 0 || value > 100)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid MaxRiskPerTrade: " + DoubleToString(value, 2));
            return false;
         }
         config.MaxRiskPerTrade = value;
      }
      else if(paramName == "TrailingStopActivationPercent")
      {
         if(value <= 0 || value > 100)
         {
            if(logger)
               logger.LogEvent("CONFIG", "ERROR", "Invalid TrailingStopActivationPercent: " + DoubleToString(value, 2));
            return false;
         }
         config.TrailingStopActivationPercent = value;
      }
      else
      {
         if(logger)
            logger.LogEvent("CONFIG", "ERROR", "Unknown parameter: " + paramName);
         return false;
      }
      if(logger)
         logger.LogEvent("CONFIG", "PARAM_SET", paramName + " = " + DoubleToString(value, 2));
      if(autoSyncEnabled)
         SaveToFile();
      return true;
   }
   double GetParameter(string strategyName, string paramName)
   {
      if(strategyName == "3BullGoDown")
         return GetParameterInternal(config3BullGoDown, paramName);
      else if(strategyName == "3BearGoDown")
         return GetParameterInternal(config3BearGoDown, paramName);
      else if(strategyName == "2Bear2BullGoUp")
         return GetParameterInternal(config2Bear2BullGoUp, paramName);
      return -1;
   }
   double GetParameterInternal(CBaseConfig &config, string paramName)
   {
      if(paramName == "LotSize") return config.LotSize;
      if(paramName == "StopLossPoints") return config.StopLossPoints;
      if(paramName == "MinSequence") return config.MinSequence;
      if(paramName == "MinCandleSize") return config.MinCandleSize;
      if(paramName == "MaxCandleSize") return config.MaxCandleSize;
      if(paramName == "MinTakeProfit") return config.MinTakeProfit;
      if(paramName == "MaxTakeProfit") return config.MaxTakeProfit;
      if(paramName == "LongSequenceMultiplier") return config.LongSequenceMultiplier;
      if(paramName == "LotCalculationType") return config.LotCalculationType;
      if(paramName == "InitialDeposit") return config.InitialDeposit;
      if(paramName == "MaxRiskPerTrade") return config.MaxRiskPerTrade;
      if(paramName == "TrailingStopActivationPercent") return config.TrailingStopActivationPercent;
      return -1;
   }
   CConfig_3BullGoDown* GetConfig3BullGoDown()
   {
      return &config3BullGoDown;
   }
   CConfig_3BearGoDown* GetConfig3BearGoDown()
   {
      return &config3BearGoDown;
   }
   CConfig_2Bear2BullGoUP* GetConfig2Bear2BullGoUp()
   {
      return &config2Bear2BullGoUp;
   }
};

#endif