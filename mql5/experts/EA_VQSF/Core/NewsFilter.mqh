#ifndef __NEWS_FILTER_MQH__
#define __NEWS_FILTER_MQH__

#include "Types.mqh"
#include "Logger.mqh"

// ================= NEWS FILTER CLASS =================
class CNewsFilter
{
private:
   int pauseMinutesBefore;
   int pauseMinutesAfter;
   int closeMinutesBefore;
   CLogger* logger;
   
   // ================= NOTÍCIAS ECONÔMICAS IMPORTANTES =================
   // Você pode expandir esta lista com mais notícias
   struct NewsEvent
   {
      int hour;
      int minute;
      string name;
      int importance; // 1=baixa, 2=média, 3=alta
   };
   
   // Notícias econômicas do calendário econômico (horários em GMT)
   NewsEvent newsEvents[50];
   int newsCount;
   
public:
   // ================= CONSTRUCTOR =================
   CNewsFilter()
   {
      pauseMinutesBefore = 0;
      pauseMinutesAfter = 0;
      closeMinutesBefore = 0;
      logger = NULL;
      newsCount = 0;
      
      LoadDefaultNewsEvents();
   }
   
   // ================= SET LOGGER =================
   void SetLogger(CLogger* log)
   {
      logger = log;
   }
   
   // ================= SET PAUSE MINUTES =================
   void SetPauseMinutes(int before, int after)
   {
      pauseMinutesBefore = before;
      pauseMinutesAfter = after;
   }
   
   // ================= SET CLOSE MINUTES =================
   void SetCloseMinutes(int before)
   {
      closeMinutesBefore = before;
   }
   
   // ================= LOAD DEFAULT NEWS EVENTS =================
   void LoadDefaultNewsEvents()
   {
      // Notícias econômicas importantes (horários em GMT)
      // Você pode adicionar mais notícias conforme necessário
      
      newsCount = 0;
      
      // NFP (Non-Farm Payroll) - Primeiro sexta-feira do mês às 13:30 GMT
      AddNewsEvent(13, 30, "NFP", 3);
      
      // FOMC Meeting - Terça-feira às 18:00 GMT
      AddNewsEvent(18, 0, "FOMC", 3);
      
      // ECB Meeting - Quinta-feira às 13:45 GMT
      AddNewsEvent(13, 45, "ECB", 3);
      
      // CPI - Segundo dia útil do mês às 13:30 GMT
      AddNewsEvent(13, 30, "CPI", 3);
      
      // PPI - Terceiro dia útil do mês às 13:30 GMT
      AddNewsEvent(13, 30, "PPI", 2);
      
      // Retail Sales - Segundo dia útil do mês às 13:30 GMT
      AddNewsEvent(13, 30, "Retail Sales", 2);
      
      // ISM Manufacturing - Primeiro dia útil do mês às 15:00 GMT
      AddNewsEvent(15, 0, "ISM Manufacturing", 2);
      
      // ISM Services - Terceiro dia útil do mês às 15:00 GMT
      AddNewsEvent(15, 0, "ISM Services", 2);
      
      // Jobless Claims - Quinta-feira às 13:30 GMT
      AddNewsEvent(13, 30, "Jobless Claims", 2);
      
      // GDP - Último dia útil do trimestre às 13:30 GMT
      AddNewsEvent(13, 30, "GDP", 3);
   }
   
   // ================= ADD NEWS EVENT =================
   void AddNewsEvent(int hour, int minute, string name, int importance)
   {
      if(newsCount >= 50)
         return;
      
      newsEvents[newsCount].hour = hour;
      newsEvents[newsCount].minute = minute;
      newsEvents[newsCount].name = name;
      newsEvents[newsCount].importance = importance;
      
      newsCount++;
   }
   
   // ================= CHECK IF NEAR NEWS EVENT =================
   bool IsNearNewsEvent(int currentHour, int currentMinute)
   {
      if(pauseMinutesBefore == 0 && pauseMinutesAfter == 0)
         return false;
      
      int currentTimeInMinutes = currentHour * 60 + currentMinute;
      
      for(int i = 0; i < newsCount; i++)
      {
         int newsTimeInMinutes = newsEvents[i].hour * 60 + newsEvents[i].minute;
         
         // Verificar se está dentro da janela de pausa ANTES
         if(pauseMinutesBefore > 0)
         {
            int beforeStart = newsTimeInMinutes - pauseMinutesBefore;
            int beforeEnd = newsTimeInMinutes;
            
            if(currentTimeInMinutes >= beforeStart && currentTimeInMinutes < beforeEnd)
            {
               if(logger)
                  logger.LogEvent("NEWS_FILTER", "PAUSE_BEFORE", 
                     "Near news event: " + newsEvents[i].name + 
                     " (in " + IntegerToString(beforeEnd - currentTimeInMinutes) + " minutes)");
               return true;
            }
         }
         
         // Verificar se está dentro da janela de pausa DEPOIS
         if(pauseMinutesAfter > 0)
         {
            int afterStart = newsTimeInMinutes;
            int afterEnd = newsTimeInMinutes + pauseMinutesAfter;
            
            if(currentTimeInMinutes >= afterStart && currentTimeInMinutes < afterEnd)
            {
               if(logger)
                  logger.LogEvent("NEWS_FILTER", "PAUSE_AFTER", 
                     "After news event: " + newsEvents[i].name + 
                     " (for " + IntegerToString(afterEnd - currentTimeInMinutes) + " more minutes)");
               return true;
            }
         }
      }
      
      return false;
   }
   
   // ================= CHECK IF SHOULD CLOSE TRADES =================
   bool ShouldCloseTrades(int currentHour, int currentMinute)
   {
      if(closeMinutesBefore == 0)
         return false;
      
      int currentTimeInMinutes = currentHour * 60 + currentMinute;
      
      for(int i = 0; i < newsCount; i++)
      {
         int newsTimeInMinutes = newsEvents[i].hour * 60 + newsEvents[i].minute;
         int closeStart = newsTimeInMinutes - closeMinutesBefore;
         int closeEnd = newsTimeInMinutes;
         
         if(currentTimeInMinutes >= closeStart && currentTimeInMinutes < closeEnd)
         {
            if(logger)
               logger.LogEvent("NEWS_FILTER", "CLOSE_TRADES", 
                  "Close trades before: " + newsEvents[i].name + 
                  " (in " + IntegerToString(closeEnd - currentTimeInMinutes) + " minutes)");
            return true;
         }
      }
      
      return false;
   }
   
   // ================= GET NEWS EVENTS COUNT =================
   int GetNewsEventsCount()
   {
      return newsCount;
   }
   
   // ================= GET NEWS EVENT =================
   string GetNewsEvent(int index)
   {
      if(index >= 0 && index < newsCount)
         return newsEvents[index].name;
      return "";
   }
};

#endif