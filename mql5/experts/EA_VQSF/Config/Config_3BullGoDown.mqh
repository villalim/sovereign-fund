#ifndef __CONFIG_3BULLGODOWN_MQH__
#define __CONFIG_3BULLGODOWN_MQH__

#include "../Core/BaseConfig.mqh"

class CConfig_3BullGoDown : public CBaseConfig
{
public:
   CConfig_3BullGoDown()
   {
      LoadDefaults();
   }
   virtual void LoadDefaults()
   {
      MagicNumber = 10001;
      Timeframe = PERIOD_M15;
      LotSize = 0.75;
      StopLossPoints = 200;
      MinSequence = 3;
      MinCandleSize = 80;
      MaxCandleSize = 1500;
      MinTakeProfit = 100;
      MaxTakeProfit = 500;
      LongSequenceMultiplier = 2.0;
      MaxDailyDrawdown = 5.0;
      MaxTotalDrawdown = 10.0;
      UseVolatilityFilter = true;
      UseNewsFilter = true;
      UseMomentumFilter = true;
      UseTimeFilter = true;
      Enabled = true;
      StartHour = 4;
      StartMinute = 0;
      EndHour = 21;
      EndMinute = 0;
      NewsFilterPauseMinutes = 0;
      NewsFilterCloseMinutes = 0;
      TrendValidationBars = 0;
      EnableTrailingStop = true;
      TrailingStopActivationPercent = 50.0;
      LotCalculationType = 0;
      InitialDeposit = 10000.0;
      MaxRiskPerTrade = 1.0;
   }
   virtual bool Validate()
   {
      if(!CBaseConfig::Validate())
         return false;
      return true;
   }
   string GetStrategyName()
   {
      return "3BullGoDown";
   }
};

#endif