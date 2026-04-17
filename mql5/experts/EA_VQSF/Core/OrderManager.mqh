#ifndef __ORDER_MANAGER_MQH__
#define __ORDER_MANAGER_MQH__

#include "Logger.mqh"
#include "Types.mqh"
#include <Trade/Trade.mqh>

struct OrderInfo
{
   ulong ticket;
   string strategy;
   int magic;
   int orderType;
   double volume;
   double openPrice;
   double stopLoss;
   double takeProfit;
   datetime creationTime;
   int durationSeconds;
   string comment;
};

class COrderManager
{
private:
   OrderInfo orders[500];
   int orderCount;
   CLogger* logger;
   CTrade trade;

public:
   COrderManager()
   {
      orderCount = 0;
      logger = NULL;
   }

   ~COrderManager()
   {
   }

   void SetLogger(CLogger* log)
   {
      logger = log;
   }

   void RefreshOrders()
   {
      orderCount = 0;

      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         
         if(OrderSelect(ticket))
         {
            if(OrderGetString(ORDER_SYMBOL) != _Symbol)
               continue;

            OrderInfo info;
            info.ticket = ticket;
            info.magic = (int)OrderGetInteger(ORDER_MAGIC);
            info.orderType = (int)OrderGetInteger(ORDER_TYPE);
            info.volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
            info.openPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            info.stopLoss = OrderGetDouble(ORDER_SL);
            info.takeProfit = OrderGetDouble(ORDER_TP);
            info.creationTime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
            info.durationSeconds = (int)(TimeCurrent() - info.creationTime);
            info.comment = OrderGetString(ORDER_COMMENT);

            if(orderCount < 500)
               orders[orderCount++] = info;
         }
      }

      if(logger)
         logger.LogDebug("ORDER_MGR", "REFRESH", "Refreshed orders: " + IntegerToString(orderCount));
   }

   int GetPendingOrderCount()
   {
      RefreshOrders();
      return orderCount;
   }

   int GetPendingOrderCountByMagic(int magic)
   {
      RefreshOrders();
      int count = 0;

      for(int i = 0; i < orderCount; i++)
      {
         if(orders[i].magic == magic)
            count++;
      }

      return count;
   }

   int GetPendingOrderCountByStrategy(string strategyName)
   {
      RefreshOrders();
      int count = 0;

      for(int i = 0; i < orderCount; i++)
      {
         if(orders[i].strategy == strategyName)
            count++;
      }

      return count;
   }

   OrderInfo GetOrder(int index)
   {
      OrderInfo empty;
      empty.ticket = 0;

      if(index >= 0 && index < orderCount)
         return orders[index];

      return empty;
   }

   bool CancelOrder(ulong ticket, CLogger &log)
   {
      if(!OrderSelect(ticket))
      {
         if(logger)
            logger.LogEvent("ORDER_MGR", "CANCEL_FAILED", "Order " + (string)ticket + " not found");
         return false;
      }

      if(trade.OrderDelete(ticket))
      {
         if(logger)
            logger.LogEvent("ORDER_MGR", "CANCEL_SUCCESS", "Order " + (string)ticket + " cancelled");
         return true;
      }
      else
      {
         if(logger)
            logger.LogEvent("ORDER_MGR", "CANCEL_ERROR", "Failed to cancel order " + (string)ticket);
         return false;
      }
   }

   bool CancelOrdersByMagic(int magic, CLogger &log)
   {
      RefreshOrders();
      int cancelledCount = 0;

      for(int i = 0; i < orderCount; i++)
      {
         if(orders[i].magic == magic)
         {
            if(CancelOrder(orders[i].ticket, log))
               cancelledCount++;
         }
      }

      if(logger)
         logger.LogEvent("ORDER_MGR", "CANCEL_BATCH", 
            "Cancelled " + IntegerToString(cancelledCount) + " orders for magic " + IntegerToString(magic));

      return (cancelledCount > 0);
   }

   bool CancelOrdersByStrategy(string strategyName, CLogger &log)
   {
      RefreshOrders();
      int cancelledCount = 0;

      for(int i = 0; i < orderCount; i++)
      {
         if(orders[i].strategy == strategyName)
         {
            if(CancelOrder(orders[i].ticket, log))
               cancelledCount++;
         }
      }

      if(logger)
         logger.LogEvent("ORDER_MGR", "CANCEL_BATCH", 
            "Cancelled " + IntegerToString(cancelledCount) + " orders for strategy " + strategyName);

      return (cancelledCount > 0);
   }

   bool CancelExpiredOrders(int maxAgeSeconds, CLogger &log)
   {
      RefreshOrders();
      int cancelledCount = 0;
      datetime now = TimeCurrent();

      for(int i = 0; i < orderCount; i++)
      {
         if((int)(now - orders[i].creationTime) > maxAgeSeconds)
         {
            if(CancelOrder(orders[i].ticket, log))
               cancelledCount++;
         }
      }

      if(logger && cancelledCount > 0)
         logger.LogEvent("ORDER_MGR", "CANCEL_EXPIRED", 
            "Cancelled " + IntegerToString(cancelledCount) + " expired orders");

      return (cancelledCount > 0);
   }

   string GetOrderDetails(int index)
   {
      if(index < 0 || index >= orderCount)
         return "";

      OrderInfo info = orders[index];
      string orderTypeStr = (info.orderType == ORDER_TYPE_BUY_LIMIT) ? "BUY_LIMIT" :
                           (info.orderType == ORDER_TYPE_SELL_LIMIT) ? "SELL_LIMIT" :
                           (info.orderType == ORDER_TYPE_BUY_STOP) ? "BUY_STOP" :
                           (info.orderType == ORDER_TYPE_SELL_STOP) ? "SELL_STOP" : "UNKNOWN";

      string details = "Ticket=" + (string)info.ticket;
      details += " | Type=" + orderTypeStr;
      details += " | Price=" + DoubleToString(info.openPrice, 5);
      details += " | Volume=" + DoubleToString(info.volume, 2);
      details += " | SL=" + DoubleToString(info.stopLoss, 5);
      details += " | TP=" + DoubleToString(info.takeProfit, 5);
      details += " | Duration=" + IntegerToString(info.durationSeconds) + "s";

      return details;
   }

   void LogOrderSummary()
   {
      RefreshOrders();

      if(logger)
      {
         logger.LogEvent("ORDER_MGR", "SUMMARY", 
            "Total Pending Orders: " + IntegerToString(orderCount));
      }

      for(int i = 0; i < orderCount; i++)
      {
         if(logger)
            logger.LogDebug("ORDER_MGR", "ORDER_DETAIL", GetOrderDetails(i));
      }
   }
};

#endif