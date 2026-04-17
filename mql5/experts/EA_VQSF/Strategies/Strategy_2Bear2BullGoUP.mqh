#ifndef __STRATEGY_2BEAR2BULLGOUP_MQH__
#define __STRATEGY_2BEAR2BULLGOUP_MQH__

#include "../Core/Types.mqh"
#include "../Core/Utils.mqh"
#include "../Core/Logger.mqh"
#include "../Core/BaseConfig.mqh"
#include "../Core/StrategyHelper.mqh"
#include "../Core/TimeHelper.mqh"
#include "BaseStrategy.mqh"

class CStrategy_2Bear2BullGoUP : public CBaseStrategy
{
private:

   string m_name;
   double bear2OpenReference;
   double lowestPrice;

   double CalculateTP()
   {
      double tp = state.largestCandle * config.LongSequenceMultiplier;
      return MathMax(tp, config.MinTakeProfit);
   }

   TradeSignal GenerateSignal(double size, double upper, double lower, double spread, double pnl)
   {
      TradeSignal signal;
      signal.valid = true;
      signal.direction = BUY;
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

   string GetName() override { return "2Bear2BullGoUP"; }

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
      double size = GetCandleSize(1, config.Timeframe);
      bool isBull = (close > open);
      bool isBear = (close < open);
      
      double pnl = AccountInfoDouble(ACCOUNT_EQUITY);
      double spread = GetSpread();
      
      log.LogDebug(m_name, "DATA", "open=" + DoubleToString(open, 5) + " close=" + DoubleToString(close, 5) + " isBull=" + (isBull ? "true" : "false"));
      log.LogDebug(m_name, "DATA", "size=" + DoubleToString(size, 2) + " lowestPrice=" + DoubleToString(lowestPrice, 5));

      if(low < lowestPrice) 
         lowestPrice = low;

      // --- FASE 0: O Primeiro BULL ---
      if(state.sequence == 0)
      {
         log.LogDebug(m_name, "TRACE", "PHASE 0 - Waiting for first BULL candle");
         
         if(isBull)
         {
            state.sequence = 1;
            state.largestCandle = size;
            lowestPrice = low;
            
            log.LogDebug(m_name, "INFO", "Sequence incremented to: 1 (first BULL detected)");
            log.LogDebug(m_name, "DATA", "largestCandle=" + DoubleToString(state.largestCandle, 2) + " lowestPrice=" + DoubleToString(lowestPrice, 5));
            log.LogEvent(m_name, "CHECK", "SEQUENCE: 1");
         }
         return signal;
      }

      // --- FASE 1 e 2: Os dois BEARS ---
      if(state.sequence == 1 || state.sequence == 2)
      {
         log.LogDebug(m_name, "TRACE", "PHASE 1/2 - Waiting for BEAR candle #" + IntegerToString(state.sequence));
         
         if(isBear)
         {
            state.sequence++;
            if(size > state.largestCandle) 
               state.largestCandle = size;
            
            log.LogDebug(m_name, "INFO", "Sequence incremented to: " + IntegerToString(state.sequence) + " (BEAR detected)");
            log.LogDebug(m_name, "DATA", "largestCandle=" + DoubleToString(state.largestCandle, 2) + " lowestPrice=" + DoubleToString(lowestPrice, 5));

            if(state.sequence == 3)
            {
               bear2OpenReference = open;
               log.LogDebug(m_name, "DATA", "bear2OpenReference=" + DoubleToString(bear2OpenReference, 5) + " (set for final validation)");
            }

            log.LogEvent(m_name, "CHECK", "SEQUENCE: " + IntegerToString(state.sequence));
         }
         else
         {
            log.LogDebug(m_name, "WARN", "Bull candle detected - breaking sequence at phase " + IntegerToString(state.sequence));
            log.LogEvent(m_name, "RESET", "SEQUENCE BROKEN AT: " + IntegerToString(state.sequence));
            state.sequence = 0;
         }
         return signal;
      }

      // --- FASE 3: O Primeiro BULL de sinal (4º candle da sequência) ---
      if(state.sequence == 3)
      {
         log.LogDebug(m_name, "TRACE", "PHASE 3 - First signal BULL after 2 BEARs (sequence=3)");
         
         if(isBull)
         {
            log.LogDebug(m_name, "DATA", "close=" + DoubleToString(close, 5) + " vs bear2OpenReference=" + DoubleToString(bear2OpenReference, 5));
            
            if(close > bear2OpenReference)
            {
               log.LogDebug(m_name, "INFO", "Close ABOVE bear2OpenReference - signal generated!");
               signal = GenerateSignal(size, GetUpperWick(1, config.Timeframe), GetLowerWick(1, config.Timeframe), spread, pnl);
               log.LogDebug(m_name, "INFO", "BUY signal generated at sequence=3 with TP=" + DoubleToString(signal.tpPoints, 2));
               log.LogEvent(m_name, "CHECK", "SEQUENCE: " + IntegerToString(state.sequence));
               log.LogFeatures(m_name, 3, size, signal.upperWick, signal.lowerWick, spread, pnl, true);
               state.sequence = 0;
            }
            else
            {
               log.LogDebug(m_name, "WARN", "Close NOT above bear2OpenReference - moving to final chance (phase 4)");
               state.sequence = 4;
               log.LogEvent(m_name, "CHECK", "SEQUENCE: " + IntegerToString(state.sequence));
            }
         }
         else
         {
            log.LogDebug(m_name, "WARN", "Bear candle detected - breaking sequence at phase 3");
            log.LogEvent(m_name, "RESET", "SEQUENCE BROKEN AT: " + IntegerToString(state.sequence));
            state.sequence = 0;
         }
         return signal;
      }

      // --- FASE 4: O Segundo BULL de sinal (5º candle da sequência - Última Chance) ---
      if(state.sequence == 4)
      {
         log.LogDebug(m_name, "TRACE", "PHASE 4 - Final chance BULL (sequence=4, last opportunity)");
         
         if(isBull)
         {
            log.LogDebug(m_name, "DATA", "close=" + DoubleToString(close, 5) + " vs bear2OpenReference=" + DoubleToString(bear2OpenReference, 5));
            
            if(close > bear2OpenReference)
            {
               log.LogDebug(m_name, "INFO", "Close ABOVE bear2OpenReference on final chance - signal generated!");
               signal = GenerateSignal(size, GetUpperWick(1, config.Timeframe), GetLowerWick(1, config.Timeframe), spread, pnl);
               log.LogDebug(m_name, "INFO", "BUY signal generated at sequence=4 with TP=" + DoubleToString(signal.tpPoints, 2));
               log.LogEvent(m_name, "CHECK", "SEQUENCE: " + IntegerToString(state.sequence));
               log.LogFeatures(m_name, 4, size, signal.upperWick, signal.lowerWick, spread, pnl, true);
               state.sequence = 0;
            }
            else
            {
               log.LogDebug(m_name, "WARN", "Close NOT above bear2OpenReference on final chance - resetting");
               log.LogEvent(m_name, "RESET", "SEQUENCE BROKEN AT: " + IntegerToString(state.sequence));
               state.sequence = 0;
            }
         }
         else
         {
            log.LogDebug(m_name, "WARN", "Bear candle detected on final chance - resetting sequence");
            log.LogEvent(m_name, "RESET", "SEQUENCE BROKEN AT: " + IntegerToString(state.sequence));
            state.sequence = 0;
         }
      }

      return signal;
   }

};

#endif