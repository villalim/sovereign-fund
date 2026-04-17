#ifndef __CONFIG_2BEAR2BULLGOUP_MQH__
#define __CONFIG_2BEAR2BULLGOUP_MQH__

#include "../Core/BaseConfig.mqh"

// ================= CONFIG 2BEAR2BULLGOUP CLASS =================
class CConfig_2Bear2BullGoUP : public CBaseConfig
{
public:
   // ================= CONSTRUCTOR =================
   CConfig_2Bear2BullGoUP()
   {
      LoadDefaults();
   }
   
   // ================= LOAD DEFAULTS =================
   void LoadDefaults() override
   {
      // Carregar defaults da classe base
      CBaseConfig::LoadDefaults();
      
      // Sobrescrever com valores específicos para 2Bear2BullGoUP
      MagicNumber = 10002;
      LotSize = 0.75;
      StopLossPoints = 200;
      
      MinSequence = 4; // 2 bears + 2 bulls
      MinCandleSize = 50;
      MaxCandleSize = 500;
      
      MinTakeProfit = 100;
      MaxTakeProfit = 500;
      LongSequenceMultiplier = 2.0;
      
      MaxDailyDrawdown = 5.0;
      MaxTotalDrawdown = 10.0;
      
      UseVolatilityFilter = true;
      UseNewsFilter = true;
      UseMomentumFilter = true;
      UseTimeFilter = true;
      EnableTrailingStop = true;                    // Ativado por padrão
      TrailingStopActivationPercent = 50.0;         // Ativa a 50% do TP
   }
};

#endif