#ifndef __BASE_CONFIG_MQH__
#define __BASE_CONFIG_MQH__

#include "Types.mqh"
#include "TimeHelper.mqh"

// ================= BASE CONFIG CLASS =================
class CBaseConfig
{
public:
   // ================= PARÂMETROS COMUNS =================
   int MagicNumber;
   ENUM_TIMEFRAMES Timeframe;
   double LotSize;
   int StopLossPoints;
   // ================= PARÂMETROS DE SEQUÊNCIA =================
   int MinSequence;
   double MinCandleSize;
   double MaxCandleSize;
   // ================= PARÂMETROS DE TP =================
   double MinTakeProfit;
   double MaxTakeProfit;
   double LongSequenceMultiplier;
   // ================= PARÂMETROS DE RISCO =================
   double MaxDailyDrawdown;
   double MaxTotalDrawdown;
   // ================= PARÂMETROS DE CÁLCULO DE LOTE (NOVO) =================
   int LotCalculationType;        // 0=Fixo, 1=Percentual
   double InitialDeposit;         // Depósito inicial para cálculo de %
   double MaxRiskPerTrade;        // Risco máximo % do depósito
   // ================= PARÂMETROS DE FILTRO =================
   bool UseVolatilityFilter;
   bool UseNewsFilter;
   bool UseMomentumFilter;
   bool UseTimeFilter;
   // ================= PARÂMETROS DE HORÁRIO =================
   bool Enabled;
   int StartHour;
   int StartMinute;
   int EndHour;
   int EndMinute;
   int NewsFilterPauseMinutes;
   int NewsFilterCloseMinutes;
   int TrendValidationBars;
   // ================= PARÂMETROS DE TRAILING STOP =================
   bool EnableTrailingStop;
   double TrailingStopActivationPercent;
   // ================= CONSTRUCTOR =================
   CBaseConfig()
   {
      LoadDefaults();
   }
   // ================= LOAD DEFAULTS =================
   virtual void LoadDefaults()
   {
      MagicNumber = 10001;
      Timeframe = PERIOD_M15;
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
      // ================= DEFAULTS DE CÁLCULO DE LOTE =================
      LotCalculationType = 0;      // Padrão: Fixo
      InitialDeposit = 10000.0;    // Depósito padrão em USD
      MaxRiskPerTrade = 2.0;       // Risco padrão 2%
      UseVolatilityFilter = true;
      UseNewsFilter = true;
      UseMomentumFilter = true;
      UseTimeFilter = true;
      // ================= DEFAULTS DE HORÁRIO =================
      Enabled = true;
      StartHour = 9;
      StartMinute = 0;
      EndHour = 17;
      EndMinute = 0;
      NewsFilterPauseMinutes = 0;
      NewsFilterCloseMinutes = 0;
      TrendValidationBars = 0;
      // ================= DEFAULTS DE TRAILING STOP =================
      EnableTrailingStop = true;
      TrailingStopActivationPercent = 50.0;
   }

   // ================= VALIDATE =================
   virtual bool Validate()
   {
      if(MagicNumber <= 0) return false;
      if(LotSize <= 0) return false;
      if(StopLossPoints <= 0) return false;
      if(MinSequence <= 0) return false;
      if(MinCandleSize <= 0) return false;
      if(MaxCandleSize <= MinCandleSize) return false;
      if(MinTakeProfit <= 0) return false;
      if(MaxTakeProfit <= MinTakeProfit) return false;
      if(LongSequenceMultiplier <= 1.0) return false;
      // ================= VALIDAR PARÂMETROS DE HORÁRIO =================
      if(StartHour < 0 || StartHour > 23) return false;
      if(StartMinute < 0 || StartMinute > 59) return false;
      if(EndHour < 0 || EndHour > 23) return false;
      if(EndMinute < 0 || EndMinute > 59) return false;
      if(NewsFilterPauseMinutes < 0) return false;
      if(NewsFilterCloseMinutes < 0) return false;
      // ================= VALIDAR PARÂMETROS DE CÁLCULO DE LOTE =================
      if(LotCalculationType < 0 || LotCalculationType > 1) return false;  // Apenas 0 ou 1 são válidos
      if(InitialDeposit <= 0) return false;  // Depósito deve ser positivo
      if(MaxRiskPerTrade <= 0 || MaxRiskPerTrade > 100) return false;  // Risco deve estar entre 0% e 100%
      // ================= VALIDAR PARÂMETROS DE TRAILING STOP =================
      if(EnableTrailingStop)
      {
         if(TrailingStopActivationPercent <= 0 || TrailingStopActivationPercent > 100)
            return false;
      }

      return true;
   }

   // ================= CHECK IF WITHIN TRADING HOURS =================
   bool IsWithinTradingHours(int currentHour, int currentMinute)
   {
      // Converter para minutos desde meia-noite
      int currentTimeInMinutes = currentHour * 60 + currentMinute;
      int startTimeInMinutes = StartHour * 60 + StartMinute;
      int endTimeInMinutes = EndHour * 60 + EndMinute;
      // Se o horário de fim é menor que o de início, significa que passa pela meia-noite
      if(endTimeInMinutes < startTimeInMinutes)
      {
         return currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes < endTimeInMinutes;
      }
      else
      {
         return currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes < endTimeInMinutes;
      }
   }
   // ================= VALIDATE TREND =================
   int ValidateTrend(double currentClose, double highestClose)
   {
      if(TrendValidationBars <= 0)
         return BUY;
         
      if(currentClose > highestClose)
         return BUY;

      else if(currentClose < highestClose)
         return SELL;

      return -1;
   }

   // ================= GET LOT CALCULATION TYPE AS STRING =================
   string GetLotCalculationTypeAsString()
   {
      if(LotCalculationType == 0)
         return "FIXED";
      else if(LotCalculationType == 1)
         return "PERCENTAGE";
      else
         return "UNKNOWN";
   }

};

#endif