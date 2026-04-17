#ifndef __STRATEGY_3BEARGODOWN_MQH__
#define __STRATEGY_3BEARGODOWN_MQH__

#include "../Core/Types.mqh"
#include "../Core/Utils.mqh"
#include "../Core/Logger.mqh"
#include "../Core/BaseConfig.mqh"
#include "../Core/StrategyHelper.mqh"
#include "../Core/TimeHelper.mqh"
#include "BaseStrategy.mqh"

class CStrategy_3BearGoDown : public CBaseStrategy
{
private:
   string m_name;

   void Reset()
   {
      state.sequence = 0;
      state.totalMove = 0.0;
      state.largestCandle = 0.0;
      if(logger) logger.LogEvent(GetName(), "RESET", "Estado da sequência resetado.");
   }

   double CalculateTP()
   {
      if(config == NULL) return 10000;
      return CStrategyHelper::CalculateTP(state.largestCandle, state.sequence, config.MinSequence, config.LongSequenceMultiplier, config.MinTakeProfit, config.MaxTakeProfit);
   }

   TradeSignal GenerateSignal(double size, double upper, double lower, double spread, double pnl, int signalDirection) 
   {   
      TradeSignal signal;         
   
      signal.valid = true;
      signal.direction = (signalDirection == 1) ? SELL : BUY;
      signal.tpPoints = CalculateTP();
      signal.slPoints = config.StopLossPoints;
      signal.lot = config.LotSize;     
      signal.strategyName = m_name;
      signal.magicNumber = config.MagicNumber;      
      signal.sequence = state.sequence;
      signal.candleSize = size;
      signal.upperWick = upper;
      signal.lowerWick = lower;
      signal.spread = spread;
      signal.maxTakeProfit = config.MaxTakeProfit;
      signal.enableTrailingStop = config.EnableTrailingStop;
      signal.trailingStopActivationPercent = config.TrailingStopActivationPercent;      
   
      return signal;
   }

public:

   string GetName() override { return "3BearGoDown"; }

   TradeSignal OnUpdate(CLogger &log) override
   {
      TradeSignal signal;
      signal.Reset();
      m_name = GetName();
      
      log.LogDebug(m_name, "TRACE", "OnUpdate started");
      
      if(config == NULL)
      {
         log.LogDebug(m_name, "ERROR", "Config is NULL - returning invalid signal");
         return signal;
      }

      double open = iOpen(_Symbol, config.Timeframe, 1);
      double close = iClose(_Symbol, config.Timeframe, 1);
      double high = iHigh(_Symbol, config.Timeframe, 1);
      double low = iLow(_Symbol, config.Timeframe, 1);
      
      double bodySize = GetCandleSize(1, config.Timeframe);
      double upperWick = GetUpperWick(1, config.Timeframe);
      double lowerWick = GetLowerWick(1, config.Timeframe);
      
      bool isBear = (close < open);

      double pnl = AccountInfoDouble(ACCOUNT_EQUITY);
      double spread = GetSpread();
      
      log.LogDebug(m_name, "DATA", "open=" + DoubleToString(open, 5) + " close=" + DoubleToString(close, 5) + " isBear=" + (isBear ? "true" : "false"));
      log.LogDebug(m_name, "DATA", "bodySize=" + DoubleToString(bodySize, 2) + " upperWick=" + DoubleToString(upperWick, 2) + " lowerWick=" + DoubleToString(lowerWick, 2));

      if(isBear)
      {
         if(bodySize >= config.MinCandleSize && bodySize <= config.MaxCandleSize)
         {
            state.sequence++;
            state.totalMove += bodySize;
            if(bodySize > state.largestCandle) state.largestCandle = bodySize;
            
            log.LogDebug(m_name, "INFO", "Sequence incremented to: " + IntegerToString(state.sequence));
            log.LogDebug(m_name, "DATA", "largestCandle=" + DoubleToString(state.largestCandle, 2) + " totalMove=" + DoubleToString(state.totalMove, 2));
            
            if(state.sequence >= config.MinSequence)
            {
               log.LogDebug(m_name, "INFO", "MinSequence reached: " + IntegerToString(state.sequence) + " >= " + IntegerToString(config.MinSequence));
               
               if(upperWick > (2 * bodySize))
               {
                  log.LogDebug(m_name, "WARN", "Upper wick too large: " + DoubleToString(upperWick, 2) + " > " + DoubleToString(2 * bodySize, 2) + " - rejecting signal");               
                  return signal;
               }
               
               log.LogDebug(m_name, "INFO", "Wick validation passed");
               
               int validationResult = ValidateCloseAgainstHistory(1, config.Timeframe, 20);
               
               if (validationResult == 1) {validationResult = 2;}               
               if (validationResult == 2) {validationResult = 1;}
               
               
               log.LogDebug(m_name, "DATA", "Close validation result: " + IntegerToString(validationResult) + " (1=SELL, 2=BUY, 0=no signal)");
               
               if(validationResult == 0)
               {
                  log.LogDebug(m_name, "WARN", "Close equal to 20-bar min - no signal generated");
                  return signal;
               }
               
               signal = GenerateSignal(bodySize, upperWick, lowerWick, spread, pnl, validationResult);
               
               string signalDir = (validationResult == 1) ? "SELL" : "BUY";
               log.LogDebug(m_name, "INFO", "Signal generated: " + signalDir + " at sequence=" + IntegerToString(state.sequence));
               log.LogEvent(m_name, "SIGNAL", "Seq=" + IntegerToString(state.sequence) + " Close validation: " + signalDir);
            }
         }
         else
         {
            log.LogDebug(m_name, "WARN", "BodySize out of range: " + DoubleToString(bodySize, 2) + " (min=" + DoubleToString(config.MinCandleSize, 2) + " max=" + DoubleToString(config.MaxCandleSize, 2) + ")");
            return signal;
         }
      }
      else if(close > open)
      {       
         log.LogDebug(m_name, "INFO", "Bull candle detected - resetting sequence from " + IntegerToString(state.sequence));
         Reset();
         return signal;
      }
      
      return signal;
   }

};

#endif