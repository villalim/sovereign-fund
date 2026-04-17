#ifndef __TYPES_MQH__
#define __TYPES_MQH__

// ================= ENUMS =================
enum TradeDirection
{
   NONE = 0,
   BUY = 1,
   SELL = 2
};

enum TrendType
{
   TREND_UPTREND = 1,
   TREND_DOWNTREND = -1,
   TREND_NEUTRAL = 0
};

// ================= TRADE SIGNAL =================
class TradeSignal
{
public:
   bool valid;
   TradeDirection direction;
   double tpPoints;
   double slPoints;
   double lot;
   string strategyName;
   datetime signalTime;
   long magicNumber;
   long tradeId;
   int sequence;
   double candleSize;
   double upperWick;
   double lowerWick;
   double spread;   
   double totalMove;
   double largestCandle;
   bool minSequenceUsed;   
   double atr;
   double volatility;
   double rsi;
   TrendType trend;
   double accountEquity;
   bool enableTrailingStop;
   double maxTakeProfit;
   
   // ✅ NOVO: TRAILING STOP PARAMETERS
   double trailingStopActivationPercent;

   // ================= CONSTRUCTOR =================
   TradeSignal()
   {
      Reset();
   }

   // ================= RESET =================
   void Reset()
   {
      valid = false;
      direction = NONE;
      tpPoints = 0;
      slPoints = 0;
      lot = 0;
      strategyName = "";
      signalTime = 0;
      magicNumber = 0;
      tradeId = 0;

      sequence = 0;
      candleSize = 0;
      upperWick = 0;
      lowerWick = 0;
      spread = 0;

      totalMove = 0;
      largestCandle = 0;
      minSequenceUsed = false;
      enableTrailingStop = true;
      maxTakeProfit = 0;
      
      // ✅ NOVO: Reset do parâmetro TS
      trailingStopActivationPercent = 50.0;
      
      atr = 0;
      volatility = 0;
      rsi = 50;
      trend = TREND_NEUTRAL;
      accountEquity = 0;
   }

   string ToStringDirection()
   {
      if(direction == BUY) return "BUY";
      if(direction == SELL) return "SELL";
      return "NONE";
   }

   string ToStringTrend()
   {
      if(trend == TREND_UPTREND) return "UPTREND";
      if(trend == TREND_DOWNTREND) return "DOWNTREND";
      return "NEUTRAL";
   }

   // ================= DEBUG =================
   string ToString()
   {
      return "valid=" + (string)valid +
             " magic=" + IntegerToString(magicNumber) +
             " dir=" + ToStringDirection() +
             " tp=" + DoubleToString(tpPoints, 1) +
             " sl=" + DoubleToString(slPoints, 1) +
             " lot=" + DoubleToString(lot, 2) +
             " strategy=" + strategyName +
             " atr=" + DoubleToString(atr, 1) +
             " rsi=" + DoubleToString(rsi, 1) +
             " trend=" + ToStringTrend() +
             " ts=" + (enableTrailingStop ? "ON@" + DoubleToString(trailingStopActivationPercent, 1) + "%" : "OFF");
   }
};

// ================= STRATEGY STATE =================
class CStrategyState
{
public:
   int sequence;
   double largestCandle;
   double totalMove;
   bool minSequenceUsed;

   // Features importantes (já pronto para ML)
   double lastCandleSize;
   double lastUpperWick;
   double lastLowerWick;
   datetime lastUpdateTime;

   // ================= CONSTRUCTOR =================
   CStrategyState()
   {
      Reset();
   }

   // ================= RESET =================
   void Reset()
   {
      sequence = 0;
      largestCandle = 0;
      totalMove = 0;
      minSequenceUsed = false;
      lastCandleSize = 0;
      lastUpperWick = 0;
      lastLowerWick = 0;
      lastUpdateTime = 0;
   }
};

// ================= TRADE RECORD (ENRIQUECIDO PARA ML) =================
class TradeRecord
{
public:
   // Identificação
   long tradeId;
   string strategy;
   datetime openTime;
   datetime closeTime;

   // Features da Candle
   int sequence;
   double candleSize;
   double upperWick;
   double lowerWick;
   double spread;

   // Features de Mercado (NOVO)
   double atr;
   double volatility;
   double rsi;
   TrendType trend;
   double accountEquity;

   // Features da Estratégia (NOVO)
   double totalMove;
   double largestCandle;
   bool minSequenceUsed;

   // Resultado
   double profit;
   double profitPercent;
   int label; // 1 = win, 0 = loss
   int durationMinutes;

   // ================= CONSTRUCTOR =================
   TradeRecord()
   {
      Reset();
   }

   // ================= RESET =================
   void Reset()
   {
      tradeId = 0;
      strategy = "";
      openTime = 0;
      closeTime = 0;

      sequence = 0;
      candleSize = 0;
      upperWick = 0;
      lowerWick = 0;
      spread = 0;

      atr = 0;
      volatility = 0;
      rsi = 50;
      trend = TREND_NEUTRAL;
      accountEquity = 0;

      totalMove = 0;
      largestCandle = 0;
      minSequenceUsed = false;

      profit = 0;
      profitPercent = 0;
      label = 0;
      durationMinutes = 0;
   }

   // ================= DEBUG =================
   string ToString()
   {
      return "tradeId=" + IntegerToString(tradeId) +
             " strategy=" + strategy +
             " sequence=" + IntegerToString(sequence) +
             " profit=" + DoubleToString(profit, 2) +
             " label=" + IntegerToString(label) +
             " atr=" + DoubleToString(atr, 1) +
             " rsi=" + DoubleToString(rsi, 1);
   }
};

#endif