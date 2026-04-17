
#ifndef __STRATEGY_HELPER_MQH__
#define __STRATEGY_HELPER_MQH__

#include "Types.mqh"

// ================= STRATEGY HELPER CLASS =================
class CStrategyHelper
  {
public:
   // ================= CALCULATE TP (PADRONIZADO) =================
   static double     CalculateTP(
      double largestCandle,
      int sequence,
      int minSequence,
      double longSequenceMultiplier,
      double minTP,
      double maxTP
   )
     {
      double tp;

      if(sequence == minSequence)
        {
         tp = largestCandle;
        }
      else
        {
         tp = largestCandle * longSequenceMultiplier;
        }

      tp = MathMax(tp, minTP);
      tp = MathMin(tp, maxTP);

      return tp;
     }

   // ================= CALCULATE LOT (PADRONIZADO) =================
   static double     CalculateLot(
      double baseLot,
      double largestCandle,
      double threshold
   )
     {
      if(largestCandle >= threshold)
        {
         return baseLot / 2;
        }
      return baseLot;
     }

   // ================= VALIDATE CANDLE (PADRONIZADO) =================
   static bool       IsValidCandle(
      double bodySize,
      double upperWick,
      double lowerWick,
      double minSize,
      double maxSize,
      int expectedDirection
   )
     {
      // ================= VALIDAR TAMANHO DO BODY =================
      // A validação é feita apenas pelo corpo (body), não pela vela completa
      if(bodySize < minSize || bodySize > maxSize)
         return false;

      // ================= VALIDAR SOMBRAS =================
      // Para LONG (3BearGoDown): sombra superior não pode ser maior que 2x o corpo
      if(expectedDirection == BUY && upperWick > (2 * bodySize))
         return false;

      // Para SHORT (3BullGoDown): sombra inferior não pode ser maior que 2x o corpo
      if(expectedDirection == SELL && lowerWick > (2 * bodySize))
         return false;

      return true;
     }

   // ================= CHECK SEQUENCE RESET =================
   static bool       ShouldResetSequence(
      double close,
      double open,
      TradeDirection expectedDirection
   )
     {
      // Para LONG (3BearGoUp): reset se fechar em baixa
      if(expectedDirection == BUY && close < open)
         return true;

      // Para SHORT (3BullGoDown): reset se fechar em alta
      if(expectedDirection == SELL && close > open)
         return true;

      return false;
     }

   // ================= CALCULATE VOLATILITY =================
   static double     CalculateVolatility(int period = 20, ENUM_TIMEFRAMES tf = PERIOD_M15)
     {
      double closes[];
      ArraySetAsSeries(closes, true);

      if(CopyClose(_Symbol, tf, 0, period, closes) <= 0)
         return 0;

      double sum = 0;
      double mean = 0;

      // Calcular média
      for(int i = 0; i < period; i++)
         mean += closes[i];
      mean /= period;

      // Calcular desvio padrão
      for(int i = 0; i < period; i++)
         sum += MathPow(closes[i] - mean, 2);

      double variance = sum / period;
      double stdDev = MathSqrt(variance);

      // Retornar volatilidade em percentual
      return (stdDev / mean) * 100;
     }

   // ================= GET TREND =================
   static TrendType  GetTrend(int period = 14, ENUM_TIMEFRAMES tf = PERIOD_M15)
     {
      double rsi = GetRSI(period, tf);

      if(rsi > 60)
         return TREND_UPTREND;
      else
         if(rsi < 40)
            return TREND_DOWNTREND;
         else
            return TREND_NEUTRAL;
     }

   // ================= GET RSI (CORRIGIDO) =================
   static double     GetRSI(int period = 14, ENUM_TIMEFRAMES tf = PERIOD_M15)
     {
      static int handle = INVALID_HANDLE;

      if(handle == INVALID_HANDLE)
         handle = iRSI(_Symbol, tf, period, PRICE_CLOSE);  // CORRIGIDO: removido parâmetro extra

      if(handle == INVALID_HANDLE)
         return 50;

      double buffer[];
      if(CopyBuffer(handle, 0, 0, 1, buffer) <= 0)
         return 50;

      return buffer[0];
     }

   // ================= GET ATR =================
   static double     GetATR(int period = 14, ENUM_TIMEFRAMES tf = PERIOD_M15)
     {
      static int handle = INVALID_HANDLE;

      if(handle == INVALID_HANDLE)
         handle = iATR(_Symbol, tf, period);

      if(handle == INVALID_HANDLE)
         return 0;

      double buffer[];
      if(CopyBuffer(handle, 0, 0, 1, buffer) <= 0)
         return 0;

      return buffer[0] / _Point;
     }
  };

#endif
//+------------------------------------------------------------------+
