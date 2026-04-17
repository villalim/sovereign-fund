#ifndef __UTILS_MQH__
#define __UTILS_MQH__

// ================= CHECK NEW CANDLE =================
bool IsNewCandle(ENUM_TIMEFRAMES tf)
{
   static datetime lastTime[21];
   int index = (int)tf;
   datetime current = iTime(_Symbol, tf, 0);
   
   if(current != lastTime[index])
   {
      lastTime[index] = current;
      return true;
   }
   return false;
}

// ================= GET SPREAD =================
double GetSpread()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(ask == 0 || bid == 0)
      return 0;
   
   return (ask - bid) / _Point;
}

// ================= GET CANDLE SIZE =================
double GetCandleSize(int shift, ENUM_TIMEFRAMES tf)
{
   double open = iOpen(_Symbol, tf, shift);
   double close = iClose(_Symbol, tf, shift);
   
   return MathAbs(close - open) / _Point;
}

// ================= GET UPPER WICK =================
double GetUpperWick(int shift, ENUM_TIMEFRAMES tf)
{
   double high = iHigh(_Symbol, tf, shift);
   double close = iClose(_Symbol, tf, shift);
   double open = iOpen(_Symbol, tf, shift);
   double top = MathMax(open, close);
   
   return (high - top) / _Point;
}

// ================= GET LOWER WICK =================
double GetLowerWick(int shift, ENUM_TIMEFRAMES tf)
{
   double low = iLow(_Symbol, tf, shift);
   double close = iClose(_Symbol, tf, shift);
   double open = iOpen(_Symbol, tf, shift);
   double bottom = MathMin(open, close);
   
   return (bottom - low) / _Point;
}

// ================= GET ATR =================
double GetATR(int period, ENUM_TIMEFRAMES tf)
{
   static int handle = INVALID_HANDLE;
   
   if(handle == INVALID_HANDLE)
      handle = iATR(_Symbol, tf, period);
   
   double buffer[];
   if(CopyBuffer(handle, 0, 0, 1, buffer) <= 0)
      return 0;
   
   return buffer[0] / _Point;
}

// ================= GET DATE OF DAY =================
datetime DateOfDay(datetime t)
{
   return (t / 86400) * 86400;
}

// ================= NORMALIZE PRICE =================
double NormalizePrice(double price)
{
   return NormalizeDouble(price, _Digits);
}

// ================= NORMALIZE VOLUME =================
double NormalizeVolume(double volume)
{
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(volume < minVolume)
      volume = minVolume;
   
   if(volume > maxVolume)
      volume = maxVolume;
   
   volume = MathRound(volume / step) * step;
   
   return NormalizeDouble(volume, 2);
}


// ================= VALIDATE CLOSE AGAINST HISTORY =================
// Valida o fechamento atual contra histórico de 50 velas anteriores
// Retorna: 1 (SELL), 2 (BUY), 0 (sem sinal/igual)
int ValidateCloseAgainstHistory(int direction, ENUM_TIMEFRAMES tf, int historicalBars = 50)
{
   double currentClose = iClose(_Symbol, tf, 1);  // Vela gatilho (shift 1)
   
   double extremeCloseUP = iClose(_Symbol, tf, 2); // Inicializa com shift 2 para BEAR (menor)
   double extremeCloseDOWN = iClose(_Symbol, tf, 2);  // Inicializa com shift 2 para BEAR (menor)
   
   // Procura o menor ou maior fechamento nas 20 velas anteriores (shift 2 até 21)
   for(int i = 2; i <= historicalBars + 1; i++)
   {
      double closePrice = iClose(_Symbol, tf, i);
      
      if (closePrice > extremeCloseUP)
         extremeCloseUP = closePrice;
      
      if (closePrice < extremeCloseDOWN)
         extremeCloseDOWN = closePrice; 
   
   }
   
   if (currentClose < extremeCloseDOWN)
      { 
      return 1;  // SELL
      }else if(currentClose > extremeCloseUP){
         return 2;  // BUY   
      }else return 0;  // Igual - sem sinal  
   
   return 0;  // Valor padrão
}

#endif