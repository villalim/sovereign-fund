#ifndef __CONFIG_3BEARGODOWN_MQH__
#define __CONFIG_3BEARGODOWN_MQH__

#include "../Core/BaseConfig.mqh"

// ================= CONFIG 3BEARGODOWN CLASS =================
class CConfig_3BearGoDown : public CBaseConfig
{
public:
   // ================= CONSTRUCTOR =================
   CConfig_3BearGoDown()
   {
      LoadDefaults();
   }
   
   // ================= LOAD DEFAULTS =================
   void LoadDefaults() override
   {
      // Carregar defaults da classe base
      CBaseConfig::LoadDefaults();
      
      // Sobrescrever com valores específicos para 3BearGoDown
      MagicNumber = 10001;
      LotSize = 0.75;
      StopLossPoints = 200;
      
      MinSequence = 3;
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
   }
   
   // ================= VALIDATE TREND (NOVO) =================
   // Retorna: BUY se close > maior close das últimas XX velas
   //          SELL se close < maior close das últimas XX velas
   //          -1 se não conseguir validar
   int ValidateTrend(double currentClose, double highestClose)
   {
      if(TrendValidationBars <= 0)
         return BUY;  // Se desligado, padrão é BUY
      
      if(currentClose > highestClose)
         return BUY;   // Trend UP
      else if(currentClose < highestClose)
         return SELL;  // Trend DOWN
      
      return -1;  // Sem validação
   }   
   
   
};

#endif