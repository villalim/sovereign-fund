#ifndef __RISK_MANAGER_MQH__
#define __RISK_MANAGER_MQH__

#include "Logger.mqh"
#include "Types.mqh"

// ================= ENUMS =================

enum ENUM_LOT_CALCULATION_TYPE
{
   LOT_CALC_FIXED = 0,       // Lote fixo definido na estratégia
   LOT_CALC_PERCENTAGE = 1   // Lote baseado em % do depósito inicial
};

// ================= RISK MANAGER CLASS =================

class CRiskManager
{
private:
   // === Global Risk Parameters ===
   double maxExposure;
   double maxPositionsCount;
   double dailyLossLimit;
   double maxDailyProfit;
   double startingEquity;
   
   // === Daily Tracking Parameters ===
   static datetime lastDailyResetTime;
   double dailyStartingEquity;
   double dailyStartingBalance;
   
   // === Global Lot Calculation Parameters ===
   double globalInitialDeposit;
   int globalLotCalculationType;
   double globalMaxRiskPerTrade;
   
   // === Per-Strategy Parameters ===
   struct StrategyRiskParams
   {
      string strategyName;
      int lotCalculationType;
      double initialDeposit;
      double maxRiskPerTrade;
      bool isConfigured;
   };
   
   StrategyRiskParams strategyParams[10];
   int strategyParamsCount;
   
   CLogger* logger;

public:
   CRiskManager()
   {
      maxExposure = 10000.0;
      maxPositionsCount = 10;
      dailyLossLimit = 500.0;
      maxDailyProfit = 4000.0;
      startingEquity = 0.0;
      
      dailyStartingEquity = 0.0;
      dailyStartingBalance = 0.0;
      lastDailyResetTime = 0;
      
      globalInitialDeposit = 10000.0;
      globalLotCalculationType = 0;
      globalMaxRiskPerTrade = 2.0;
      
      strategyParamsCount = 0;
      logger = NULL;
      
      // Inicializar array de estratégias
      for(int i = 0; i < 10; i++)
      {
         strategyParams[i].isConfigured = false;
         strategyParams[i].strategyName = "";
      }
   }

   ~CRiskManager()
   {
   }

   // ================= LOGGER =================

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   // ================= GLOBAL SETTERS =================

   void SetGlobalInitialDeposit(double deposit)
   {
      globalInitialDeposit = deposit;
      if(logger)
         logger.LogEvent("RISK_MGR", "CONFIG", "Global initial deposit: " + DoubleToString(deposit, 2));
   }

   void SetGlobalLotCalculationType(int type)
   {
      globalLotCalculationType = type;
      string typeStr = (type == LOT_CALC_FIXED) ? "FIXED" : "PERCENTAGE";
      if(logger)
         logger.LogEvent("RISK_MGR", "CONFIG", "Global lot calculation type: " + typeStr);
   }

   void SetGlobalMaxRiskPerTrade(double riskPercent)
   {
      globalMaxRiskPerTrade = riskPercent;
      if(logger)
         logger.LogEvent("RISK_MGR", "CONFIG", "Global max risk per trade: " + DoubleToString(riskPercent, 2) + "%");
   }

   void SetMaxExposure(double exposure)
   {
      maxExposure = exposure;
      if(logger)
         logger.LogEvent("RISK_MGR", "CONFIG", "Max exposure: " + DoubleToString(exposure, 2));
   }

   void SetMaxPositionsCount(int count)
   {
      maxPositionsCount = count;
      if(logger)
         logger.LogEvent("RISK_MGR", "CONFIG", "Max concurrent positions: " + IntegerToString(count));
   }

   void SetDailyLossLimit(double limit)
   {
      dailyLossLimit = limit;
      if(logger)
         logger.LogEvent("RISK_MGR", "CONFIG", "Daily loss limit: " + DoubleToString(limit, 2));
   }

   void SetMaxDailyProfit(double limit)
   {
      maxDailyProfit = limit;
      if(logger)
         logger.LogEvent("RISK_MGR", "CONFIG", "Max daily profit: " + DoubleToString(limit, 2));
   }

   // ================= PER-STRATEGY CONFIGURATION =================

   bool SetStrategyLotConfiguration(string strategyName, int lotCalculationType, double initialDeposit, double maxRiskPerTrade)
   {
      // Procurar estratégia existente
      for(int i = 0; i < strategyParamsCount; i++)
      {
         if(strategyParams[i].strategyName == strategyName)
         {
            strategyParams[i].lotCalculationType = lotCalculationType;
            strategyParams[i].initialDeposit = initialDeposit;
            strategyParams[i].maxRiskPerTrade = maxRiskPerTrade;
            strategyParams[i].isConfigured = true;
            
            if(logger)
            {
               string typeStr = (lotCalculationType == LOT_CALC_FIXED) ? "FIXED" : "PERCENTAGE";
               logger.LogEvent("RISK_MGR", "STRATEGY_CONFIG",
                  "Strategy: " + strategyName + " | Type: " + typeStr + 
                  " | Deposit: " + DoubleToString(initialDeposit, 2) + 
                  " | Risk: " + DoubleToString(maxRiskPerTrade, 2) + "%");
            }
            return true;
         }
      }
      
      // Adicionar nova estratégia se houver espaço
      if(strategyParamsCount < 10)
      {
         strategyParams[strategyParamsCount].strategyName = strategyName;
         strategyParams[strategyParamsCount].lotCalculationType = lotCalculationType;
         strategyParams[strategyParamsCount].initialDeposit = initialDeposit;
         strategyParams[strategyParamsCount].maxRiskPerTrade = maxRiskPerTrade;
         strategyParams[strategyParamsCount].isConfigured = true;
         
         if(logger)
         {
            string typeStr = (lotCalculationType == LOT_CALC_FIXED) ? "FIXED" : "PERCENTAGE";
            logger.LogEvent("RISK_MGR", "STRATEGY_CONFIG_NEW",
               "Strategy: " + strategyName + " | Type: " + typeStr + 
               " | Deposit: " + DoubleToString(initialDeposit, 2) + 
               " | Risk: " + DoubleToString(maxRiskPerTrade, 2) + "%");
         }
         
         strategyParamsCount++;
         return true;
      }
      
      if(logger)
         logger.LogEvent("RISK_MGR", "ERROR", "Max strategies reached - cannot add " + strategyName);
      
      return false;
   }

   // ================= GET STRATEGY PARAMS (HELPER) =================

   StrategyRiskParams GetStrategyParams(string strategyName)
   {
      // Procurar configuração específica da estratégia
      for(int i = 0; i < strategyParamsCount; i++)
      {
         if(strategyParams[i].strategyName == strategyName && strategyParams[i].isConfigured)
         {
            return strategyParams[i];
         }
      }
      
      // Retornar parâmetros globais como fallback
      StrategyRiskParams fallback;
      fallback.strategyName = strategyName;
      fallback.lotCalculationType = globalLotCalculationType;
      fallback.initialDeposit = globalInitialDeposit;
      fallback.maxRiskPerTrade = globalMaxRiskPerTrade;
      fallback.isConfigured = false;
      
      return fallback;
   }

   // ================= INITIALIZATION =================

   void InitializeStartingEquity()
   {
      startingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(logger)
         logger.LogEvent("RISK_MGR", "INIT", "Starting equity: " + DoubleToString(startingEquity, 2));
   }

   // ================= DAILY LIMITS MANAGEMENT =================

   void CheckAndResetDailyLimits()
   {
      datetime now = TimeCurrent();
      MqlDateTime timeStruct;
      TimeToStruct(now, timeStruct);
      
      // Calcular midnight do dia atual (00:00:00)
      datetime todayMidnight = StructToTime(timeStruct) - (timeStruct.hour * 3600 + timeStruct.min * 60 + timeStruct.sec);
      
      // Verificar se é um novo dia
      if(lastDailyResetTime < todayMidnight)
      {
         dailyStartingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
         dailyStartingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         lastDailyResetTime = todayMidnight;
         
         // ✅ Usar o logger da classe (já definido)
         if(logger)
         {
            logger.LogEvent("RISK_MGR", "DAILY_RESET", 
               "Daily limits reset | Date: " + TimeToString(now) + 
               " | StartEquity: " + DoubleToString(dailyStartingEquity, 2) + 
               " | StartBalance: " + DoubleToString(dailyStartingBalance, 2));
         }
      }
   }

   double GetDailyLossAmount()
   {
      double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      double dailyLoss = dailyStartingEquity - currentEquity;
      return (dailyLoss > 0) ? dailyLoss : 0;
   }

   double GetDailyProfitAmount()
   {
      double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double dailyProfit = currentBalance - dailyStartingBalance;
      return (dailyProfit > 0) ? dailyProfit : 0;
   }

   bool IsDailyLossExceeded()
   {
      return GetDailyLossAmount() > dailyLossLimit;
   }

   bool IsDailyProfitExceeded()
   {
      return GetDailyProfitAmount() > maxDailyProfit;
   }

   // ================= EQUITY & DRAWDOWN QUERIES =================

   double GetCurrentEquity()
   {
      return AccountInfoDouble(ACCOUNT_EQUITY);
   }

   double GetCurrentBalance()
   {
      return AccountInfoDouble(ACCOUNT_BALANCE);
   }

   double GetDrawdown()
   {
      double currentEquity = GetCurrentEquity();
      if(startingEquity <= 0.0)
         return 0.0;
      return startingEquity - currentEquity;
   }

   double GetDrawdownPercent()
   {
      if(startingEquity <= 0.0)
         return 0.0;
      double drawdown = GetDrawdown();
      return (drawdown / startingEquity) * 100.0;
   }

   bool IsRiskLimitExceeded()
   {
      if(GetDailyLossAmount() >= dailyLossLimit)
      {
         if(logger)
            logger.LogEvent("RISK_MGR", "LIMIT_EXCEEDED",
               "Daily loss limit exceeded: " + DoubleToString(GetDailyLossAmount(), 2) + " >= " + DoubleToString(dailyLossLimit, 2));
         return true;
      }
      return false;
   }

   // ================= LOT SIZE CALCULATION (MAIN METHOD) =================

   double CalculateLotSize(double stopLossPoints, string strategyName, double fixedLotSize)
   {
      if(stopLossPoints <= 0.0)
      {
         if(logger)
            logger.LogEvent("RISK_MGR", "LOT_CALC_ERROR", "Invalid stopLossPoints: " + DoubleToString(stopLossPoints, 2));
         return 0.0;
      }
      StrategyRiskParams params = GetStrategyParams(strategyName);
      // ===== MODE 0: FIXED LOT =====
      if(params.lotCalculationType == LOT_CALC_FIXED)
      {
         if(logger)
            logger.LogDebug("RISK_MGR", "LOT_CALC_FIXED",
               "Strategy: " + strategyName + " | FixedLot: " + DoubleToString(fixedLotSize, 2));
         return fixedLotSize;
      }
      // ===== MODE 1: PERCENTAGE-BASED LOT =====
      if(params.lotCalculationType == LOT_CALC_PERCENTAGE)
      {
         // 1. Calcular risco em USD
         double riskAmount = (params.initialDeposit * params.maxRiskPerTrade) / 100.0;
         // 2. Calcular value do ponto em USD
         double pointValue = GetSymbolPointValue(_Symbol);
         if(pointValue <= 0.0)
         {
            if(logger)
               logger.LogEvent("RISK_MGR", "LOT_CALC_ERROR", "Cannot determine point value for " + _Symbol);
            return fixedLotSize; // Fallback para lote fixo
         }
         // 3. Calcular risco por ponto
         double riskPerPoint = stopLossPoints * pointValue;
         // 4. Calcular tamanho do lote
         double calculatedLot = riskAmount / riskPerPoint;
         // 5. Truncar para 2 casas decimais (arredondar para baixo)
         double truncatedLot = TruncateToDecimals(calculatedLot, 2);
         // 6. Validar contra limites da corretora
         double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
         double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
         if(truncatedLot < minLot)
         {
            truncatedLot = minLot;
            if(logger)
               logger.LogDebug("RISK_MGR", "LOT_ADJUSTED_MIN",
                  "Strategy: " + strategyName + " | CalculatedLot: " + DoubleToString(calculatedLot, 2) +
                  " | AdjustedLot (Min): " + DoubleToString(truncatedLot, 2));
         }
         else if(truncatedLot > maxLot)
         {
            truncatedLot = maxLot;
            if(logger)
               logger.LogDebug("RISK_MGR", "LOT_ADJUSTED_MAX",
                  "Strategy: " + strategyName + " | CalculatedLot: " + DoubleToString(calculatedLot, 2) +
                  " | AdjustedLot (Max): " + DoubleToString(truncatedLot, 2));
         }
         // 7. Log detalhado
         if(logger)
            logger.LogEvent("RISK_MGR", "LOT_CALC_PERCENTAGE",
               "Strategy: " + strategyName +
               " | RiskAmount: " + DoubleToString(riskAmount, 2) +
               " | PointValue: " + DoubleToString(pointValue, 4) +
               " | RiskPerPoint: " + DoubleToString(riskPerPoint, 2) +
               " | CalculatedLot: " + DoubleToString(calculatedLot, 4) +
               " | FinalLot: " + DoubleToString(truncatedLot, 2));
         return truncatedLot;
      }
      // Tipo inválido
      if(logger)
         logger.LogEvent("RISK_MGR", "LOT_CALC_ERROR", "Invalid lot calculation type: " + IntegerToString(params.lotCalculationType));
      
      return fixedLotSize;
   }

   // ================= POSITION VALIDATION WITH LOT CHECK =================

   bool CanOpenPosition(double positionRisk, double proposedLotSize)
   {
      double currentExposure = GetTotalExposure();
      double equity = GetCurrentEquity();
      // ===== FILTRO 1: Risco por Trade =====
      double riskAmount = (equity * globalMaxRiskPerTrade) / 100.0;
      if(positionRisk > riskAmount)
      {
         if(logger)
            logger.LogEvent("RISK_MGR", "RISK_LIMIT",
               "Position risk " + DoubleToString(positionRisk, 2) + " exceeds limit " + DoubleToString(riskAmount, 2));
         return false;
      }
      // ===== FILTRO 2: Exposição Total =====
      if(currentExposure + positionRisk > maxExposure)
      {
         if(logger)
            logger.LogEvent("RISK_MGR", "EXPOSURE_LIMIT",
               "Total exposure " + DoubleToString(currentExposure + positionRisk, 2) + " exceeds limit " + DoubleToString(maxExposure, 2));
         return false;
      }
      // ===== FILTRO 3: Limite de Posições =====
      if(PositionsTotal() >= (int)maxPositionsCount)
      {
         if(logger)
            logger.LogEvent("RISK_MGR", "POSITION_LIMIT",
               "Max positions count (" + IntegerToString((int)maxPositionsCount) + ") reached");
         return false;
      }
      // ===== FILTRO 4: Limite de Perda Diária =====
      if(IsRiskLimitExceeded())
      {
         if(logger)
            logger.LogEvent("RISK_MGR", "DAILY_LOSS_LIMIT", "Daily loss limit exceeded");
         return false;
      }
      // ===== FILTRO 5: Validação de Lote =====
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      
      if(proposedLotSize < minLot || proposedLotSize > maxLot)
      {
         if(logger)
            logger.LogEvent("RISK_MGR", "LOT_INVALID",
               "Proposed lot " + DoubleToString(proposedLotSize, 2) + 
               " outside valid range [" + DoubleToString(minLot, 2) + ", " + DoubleToString(maxLot, 2) + "]");
         return false;
      }
      return true;
   }

   // ================= EXPOSURE CALCULATION =================

   double GetTotalExposure()
   {
      double totalExposure = 0.0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
               double volume = PositionGetDouble(POSITION_VOLUME);
               double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               totalExposure += volume * entryPrice;
            }
         }
      }
      return totalExposure;
   }

   double CalculatePositionRisk(double volume, double entryPrice, double stopLoss)
   {
      if(entryPrice <= 0.0)
         return 0.0;
      double riskPerUnit = MathAbs(entryPrice - stopLoss);
      double totalRisk = volume * riskPerUnit;
      return totalRisk;
   }

   // ================= HELPER FUNCTIONS =================

   double TruncateToDecimals(double value, int decimals)
   {
      double multiplier = MathPow(10.0, decimals);
      return MathFloor(value * multiplier) / multiplier;
   }

   double GetSymbolPointValue(string symbol)
   {
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize == 0.0)
         tickSize = _Point;
      if(tickSize == 0.0 || tickValue == 0.0)
         return 0.0;
      return tickValue / tickSize;
   }

   // ================= REPORTING =================

   string GetRiskReport()
   {
      string report = "=== RISK REPORT ===\n";
      report += "Equity: " + DoubleToString(GetCurrentEquity(), 2) + "\n";
      report += "Balance: " + DoubleToString(GetCurrentBalance(), 2) + "\n";
      report += "Drawdown: " + DoubleToString(GetDrawdown(), 2) + " (" + DoubleToString(GetDrawdownPercent(), 2) + "%)\n";
      report += "Total Exposure: " + DoubleToString(GetTotalExposure(), 2) + " / " + DoubleToString(maxExposure, 2) + "\n";
      report += "Open Positions: " + IntegerToString(PositionsTotal()) + " / " + IntegerToString((int)maxPositionsCount) + "\n";
      report += "Daily Loss Limit: " + DoubleToString(dailyLossLimit, 2) + "\n";
      report += "Daily Loss Amount: " + DoubleToString(GetDailyLossAmount(), 2) + "\n";
      report += "Daily Profit Amount: " + DoubleToString(GetDailyProfitAmount(), 2) + "\n";
      report += "Max Daily Profit: " + DoubleToString(maxDailyProfit, 2) + "\n";
      report += "Global Risk per Trade: " + DoubleToString(globalMaxRiskPerTrade, 2) + "%\n";
      report += "Global Initial Deposit: " + DoubleToString(globalInitialDeposit, 2) + "\n";
      report += "Active Strategy Configs: " + IntegerToString(strategyParamsCount) + "\n";
      return report;
   }

   void LogRiskReport()
   {
      if(logger)
      {
         logger.LogEvent("RISK_MGR", "REPORT", GetRiskReport());
      }
   }

};

// ================= STATIC MEMBER INITIALIZATION =================

static datetime CRiskManager::lastDailyResetTime = 0;

#endif