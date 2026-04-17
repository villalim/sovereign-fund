#ifndef __DAILY_LIMITS_MQH__
#define __DAILY_LIMITS_MQH__

#include "Types.mqh"
#include "Logger.mqh"

// ================= DAILY LIMITS CLASS =================
class CDailyLimits
{
private:
   int dailyCloseHour;           // Hora para encerrar todos os trades
   int dailyCloseMinute;         // Minuto para encerrar todos os trades
   double maxDailyLoss;          // Máximo de perda diária em dinheiro
   double maxDailyProfit;        // Máximo de ganho diário em dinheiro
   
   double dailyOpeningBalance;   // Saldo no início do dia
   datetime lastDayChecked;      // Último dia verificado
   CLogger* logger;
   
public:
   // ================= CONSTRUCTOR =================
   CDailyLimits()
   {
      dailyCloseHour = 0;
      dailyCloseMinute = 0;
      maxDailyLoss = 0;
      maxDailyProfit = 0;
      dailyOpeningBalance = 0;
      lastDayChecked = 0;
      logger = NULL;
   }
   
   // ================= SET LOGGER =================
   void SetLogger(CLogger* log)
   {
      logger = log;
   }
   
   // ================= SET DAILY CLOSE TIME =================
   void SetDailyCloseTime(int hour, int minute)
   {
      dailyCloseHour = hour;
      dailyCloseMinute = minute;
   }
   
   // ================= SET MAX DAILY LOSS =================
   void SetMaxDailyLoss(double loss)
   {
      maxDailyLoss = loss;
   }
   
   // ================= SET MAX DAILY PROFIT =================
   void SetMaxDailyProfit(double profit)
   {
      maxDailyProfit = profit;
   }
   
   // ================= INITIALIZE DAILY BALANCE =================
   void InitializeDailyBalance(double currentBalance)
   {
      datetime now = TimeCurrent();
      MqlDateTime timeStruct;
      TimeToStruct(now, timeStruct);
      
      // Se é um novo dia, resetar o saldo de abertura
      if(lastDayChecked == 0)
      {
         dailyOpeningBalance = currentBalance;
         lastDayChecked = now;
         
         if(logger)
            logger.LogEvent("DAILY_LIMITS", "INIT", 
               "Daily opening balance: " + DoubleToString(dailyOpeningBalance, 2));
      }
      else
      {
         MqlDateTime lastDayStruct;
         TimeToStruct(lastDayChecked, lastDayStruct);
         
         // Verificar se mudou de dia
         if(lastDayStruct.day != timeStruct.day || 
            lastDayStruct.mon != timeStruct.mon || 
            lastDayStruct.year != timeStruct.year)
         {
            dailyOpeningBalance = currentBalance;
            lastDayChecked = now;
            
            if(logger)
               logger.LogEvent("DAILY_LIMITS", "NEW_DAY", 
                  "New day - Opening balance: " + DoubleToString(dailyOpeningBalance, 2));
         }
      }
   }
   
   // ================= CHECK IF SHOULD CLOSE FOR DAY =================
   bool ShouldCloseForDay()
   {
      // Se DailyCloseHour é 0, não fecha no dia
      if(dailyCloseHour == 0)
         return false;
      
      datetime now = TimeCurrent();
      MqlDateTime timeStruct;
      TimeToStruct(now, timeStruct);
      
      int currentTimeInMinutes = timeStruct.hour * 60 + timeStruct.min;
      int closeTimeInMinutes = dailyCloseHour * 60 + dailyCloseMinute;
      
      return currentTimeInMinutes >= closeTimeInMinutes;
   }
   
   // ================= CALCULATE CURRENT DAILY P&L =================
   double CalculateDailyPnL(double currentBalance)
   {
      return currentBalance - dailyOpeningBalance;
   }
   
   // ================= CHECK IF DAILY LOSS LIMIT REACHED =================
   bool IsDailyLossLimitReached(double currentBalance)
   {
      // Se MaxDailyLoss é 0 ou negativo, limite desligado
      if(maxDailyLoss <= 0)
         return false;
      
      double dailyPnL = CalculateDailyPnL(currentBalance);
      
      // Se a perda é maior que o limite, retorna true
      return dailyPnL <= -maxDailyLoss;
   }
   
   // ================= CHECK IF DAILY PROFIT LIMIT REACHED =================
   bool IsDailyProfitLimitReached(double currentBalance)
   {
      // Se MaxDailyProfit é 0 ou negativo, limite desligado
      if(maxDailyProfit <= 0)
         return false;
      
      double dailyPnL = CalculateDailyPnL(currentBalance);
      
      // Se o ganho é maior que o limite, retorna true
      return dailyPnL >= maxDailyProfit;
   }
   
   // ================= GET DAILY P&L =================
   double GetDailyPnL(double currentBalance)
   {
      return CalculateDailyPnL(currentBalance);
   }
   
   // ================= GET DAILY OPENING BALANCE =================
   double GetDailyOpeningBalance()
   {
      return dailyOpeningBalance;
   }
   
   // ================= GET MAX DAILY LOSS =================
   double GetMaxDailyLoss()
   {
      return maxDailyLoss;
   }
   
   // ================= GET MAX DAILY PROFIT =================
   double GetMaxDailyProfit()
   {
      return maxDailyProfit;
   }
   
   // ================= GET DAILY CLOSE HOUR =================
   int GetDailyCloseHour()
   {
      return dailyCloseHour;
   }
   
   // ================= GET DAILY CLOSE MINUTE =================
   int GetDailyCloseMinute()
   {
      return dailyCloseMinute;
   }
};

#endif