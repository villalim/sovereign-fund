#ifndef __LOGGER_MQH__
#define __LOGGER_MQH__

#include "../Core/Utils.mqh"
#include "../Core/MemoryBuffer.mqh"

class CLogger
{
private:
   int fileOps;
   int fileML;
   int fileDebug;
   int flushCounter;
   
   CMemoryBuffer bufferOps;
   CMemoryBuffer bufferML;
   CMemoryBuffer bufferDebug;
   
   bool headerWrittenOps;
   bool headerWrittenML;
   bool headerWrittenDebug;

public:
   void Init()
   {
      flushCounter = 0;
      headerWrittenOps = false;
      headerWrittenML = false;
      headerWrittenDebug = false;
      
      fileOps = FileOpen(
         "LOG_OPERATIONS.csv",
         FILE_WRITE|FILE_CSV|FILE_READ|FILE_SHARE_WRITE|FILE_COMMON,
         ';'
      );
      
      if(fileOps != INVALID_HANDLE)
      {
         FileSeek(fileOps, 0, SEEK_END);
         if(FileTell(fileOps) == 0)
         {
            FileWrite(fileOps,
               "time","strategy","event","details","price","spread","equity");
            headerWrittenOps = true;
         }
      }
      else
      {
         Print("Erro ao abrir LOG_OPERATIONS.csv");
      }
      
      fileML = FileOpen(
         "ML_DATASET.csv",
         FILE_WRITE|FILE_READ|FILE_CSV|FILE_SHARE_WRITE|FILE_COMMON,
         ';'
      );
      
      if(fileML != INVALID_HANDLE)
      {
         FileSeek(fileML, 0, SEEK_END);
         if(FileTell(fileML) == 0)
         {
            FileWrite(fileML,
               "time","strategy",
               "sequence","candleSize",
               "upperWick","lowerWick",
               "spread","pnl",
               "signal");
            headerWrittenML = true;
         }
      }
      else
      {
         Print("Erro ao abrir ML_DATASET.csv");
      }
      
      fileDebug = FileOpen(
         "DEBUG_ANALYSIS.log",
         FILE_WRITE|FILE_READ|FILE_TXT|FILE_SHARE_WRITE|FILE_COMMON
      );
      
      if(fileDebug != INVALID_HANDLE)
      {
         FileSeek(fileDebug, 0, SEEK_END);
         if(FileTell(fileDebug) == 0)
         {
            FileWrite(fileDebug, "time|strategy|level|message");
            headerWrittenDebug = true;
         }
      }
      else
      {
         Print("Erro ao abrir DEBUG_ANALYSIS.log");
      }
      
      Print("COMMON PATH: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH));
   }

   void LogEvent(string strategy, string event, string details, double price=0)
   {
      if(fileOps == INVALID_HANDLE) return;
      
      double spread = GetSpread();
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      
      string line = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ";" +
                    strategy + ";" +
                    event + ";" +
                    details + ";" +
                    DoubleToString(price, 5) + ";" +
                    DoubleToString(spread, 2) + ";" +
                    DoubleToString(equity, 2);
      
      bufferOps.Append(line);
      FlushControl();
   }

   void LogFeatures(
      string strategy,
      int sequence,
      double candleSize,
      double upperWick,
      double lowerWick,
      double spread,
      double pnl,
      bool signal
   )
   {
      if(fileML == INVALID_HANDLE) return;
      
      string line = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ";" +
                    strategy + ";" +
                    IntegerToString(sequence) + ";" +
                    DoubleToString(candleSize, 2) + ";" +
                    DoubleToString(upperWick, 2) + ";" +
                    DoubleToString(lowerWick, 2) + ";" +
                    DoubleToString(spread, 2) + ";" +
                    DoubleToString(pnl, 2) + ";" +
                    (signal ? "1" : "0");
      
      bufferML.Append(line);
      FlushControl();
   }

   void LogDebug(string strategy, string level, string message)
   {
      if(fileDebug == INVALID_HANDLE) return;
      
      string line = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "|" +
                    strategy + "|" +
                    level + "|" +
                    message;
      
      bufferDebug.Append(line);
      FlushControl();
   }

   void FlushControl()
   {
      flushCounter++;
      
      if(bufferOps.ShouldFlush() && fileOps != INVALID_HANDLE)
      {
         FileSeek(fileOps, 0, SEEK_END);
         FileWriteString(fileOps, bufferOps.GetContent() + "\n");
         FileFlush(fileOps);
         bufferOps.Clear();
      }
      
      if(bufferML.ShouldFlush() && fileML != INVALID_HANDLE)
      {
         FileSeek(fileML, 0, SEEK_END);
         FileWriteString(fileML, bufferML.GetContent() + "\n");
         FileFlush(fileML);
         bufferML.Clear();
      }
      
      if(bufferDebug.ShouldFlush() && fileDebug != INVALID_HANDLE)
      {
         FileSeek(fileDebug, 0, SEEK_END);
         FileWriteString(fileDebug, bufferDebug.GetContent() + "\n");
         FileFlush(fileDebug);
         bufferDebug.Clear();
      }
   }

   void Close()
   {
      if(bufferOps.GetLineCount() > 0 && fileOps != INVALID_HANDLE)
      {
         FileSeek(fileOps, 0, SEEK_END);
         FileWriteString(fileOps, bufferOps.GetContent() + "\n");
         bufferOps.Clear();
      }
      
      if(bufferML.GetLineCount() > 0 && fileML != INVALID_HANDLE)
      {
         FileSeek(fileML, 0, SEEK_END);
         FileWriteString(fileML, bufferML.GetContent() + "\n");
         bufferML.Clear();
      }
      
      if(bufferDebug.GetLineCount() > 0 && fileDebug != INVALID_HANDLE)
      {
         FileSeek(fileDebug, 0, SEEK_END);
         FileWriteString(fileDebug, bufferDebug.GetContent() + "\n");
         bufferDebug.Clear();
      }
      
      if(fileOps != INVALID_HANDLE) FileClose(fileOps);
      if(fileML != INVALID_HANDLE) FileClose(fileML);
      if(fileDebug != INVALID_HANDLE) FileClose(fileDebug);
   }
};

#endif