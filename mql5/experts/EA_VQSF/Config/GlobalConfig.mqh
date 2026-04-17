#ifndef __GLOBAL_CONFIG_MQH__
#define __GLOBAL_CONFIG_MQH__

class CGlobalConfig
{
public:
   // Horário
   int StartHour;
   int StartMinute;
   int EndHour;
   int EndMinute;
   int BrokerGMTOffset;

   // Risco
   double MaxDailyProfit;
   double MaxDailyLoss;
   bool CloseOnLimit;
   double MaxSpread;

   void Load(
      int sh, int sm,
      int eh, int em,
      int offset,
      double maxProfit,
      double maxLoss,
      bool closeOnLimit,
      double maxSpread
   )
   {
      StartHour = sh;
      StartMinute = sm;
      EndHour = eh;
      EndMinute = em;
      BrokerGMTOffset = offset;

      MaxDailyProfit = maxProfit;
      MaxDailyLoss = maxLoss;
      CloseOnLimit = closeOnLimit;
      MaxSpread = maxSpread;
   }
};

#endif