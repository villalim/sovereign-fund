#ifndef __BASE_STRATEGY_MQH__
#define __BASE_STRATEGY_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
#include "../Core/BaseConfig.mqh"
#include "../Core/NewsFilter.mqh"

// ================= BASE STRATEGY CLASS =================
class CBaseStrategy
{
protected:
   CStrategyState state;
   CBaseConfig* config;
   CLogger* logger;
   
public:
   // ================= CONSTRUCTOR =================
   CBaseStrategy()
   {
      config = NULL;
      logger = NULL;
   }
   
   // ================= DESTRUCTOR =================
   virtual ~CBaseStrategy()
   {
      // Não deletar config e logger pois são gerenciados externamente
   }
   
   // ================= SET CONFIG =================
   virtual void SetConfig(CBaseConfig* cfg)
   {
      config = cfg;
   }
   
   // ================= SET LOGGER =================
   virtual void SetLogger(CLogger* log)
   {
      logger = log;
   }
   
   // ================= ON UPDATE (INTERFACE) =================
   virtual TradeSignal OnUpdate(CLogger &log) = 0;
   
   // ================= RESET =================
   virtual void Reset()
   {
      state.Reset();
   }
   
   // ================= GET NAME =================
   virtual string GetName() = 0;
   
   // ================= GET STATE =================
   virtual CStrategyState* GetState()
   {
      return &state;
   }
   
   // ================= VALIDATE CONFIG =================
   virtual bool ValidateConfig()
   {
      if(config == NULL)
         return false;
      
      return config.Validate();
   }
   
   // ================= CHECK IF STRATEGY IS ENABLED =================
   virtual bool IsStrategyEnabled()
   {
      if(config == NULL)
         return false;
      
      return config.Enabled;
   }
   
   // ================= CHECK IF WITHIN TRADING HOURS =================
   virtual bool IsWithinTradingHours(int currentHour, int currentMinute)
   {
      if(config == NULL)
         return false;
      
      return config.IsWithinTradingHours(currentHour, currentMinute);
   }
   
   // ================= CHECK IF SHOULD PAUSE DUE TO NEWS =================
   virtual bool ShouldPauseDueToNews(CNewsFilter &newsFilter, int currentHour, int currentMinute)
   {
      if(config == NULL)
         return false;
      
      // Se NewsFilterPauseMinutes é 0, filtro está desligado
      if(config.NewsFilterPauseMinutes == 0)
         return false;
      
      // Configurar o filtro com os minutos da estratégia
      newsFilter.SetPauseMinutes(config.NewsFilterPauseMinutes, config.NewsFilterPauseMinutes);
      
      return newsFilter.IsNearNewsEvent(currentHour, currentMinute);
   }
   
   // ================= CHECK IF SHOULD CLOSE TRADES DUE TO NEWS =================
   virtual bool ShouldCloseTradesDueToNews(CNewsFilter &newsFilter, int currentHour, int currentMinute)
   {
      if(config == NULL)
         return false;
      
      // Se NewsFilterCloseMinutes é 0, filtro está desligado
      if(config.NewsFilterCloseMinutes == 0)
         return false;
      
      // Configurar o filtro com os minutos da estratégia
      newsFilter.SetCloseMinutes(config.NewsFilterCloseMinutes);
      
      return newsFilter.ShouldCloseTrades(currentHour, currentMinute);
   }
};

#endif