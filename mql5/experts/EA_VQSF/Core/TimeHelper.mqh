#ifndef __TIME_HELPER_MQH__
#define __TIME_HELPER_MQH__

// ================= TIME HELPER CLASS =================
class CTimeHelper
{
public:
   // ================= GET CURRENT HOUR =================
   static int GetCurrentHour()
   {
      MqlDateTime timeStruct;
      TimeToStruct(TimeLocal(), timeStruct);
      return timeStruct.hour;
   }
   
   // ================= GET CURRENT MINUTE =================
   static int GetCurrentMinute()
   {
      MqlDateTime timeStruct;
      TimeToStruct(TimeLocal(), timeStruct);
      return timeStruct.min;
   }
   
   // ================= GET CURRENT HOUR AND MINUTE =================
   static void GetCurrentTime(int &hour, int &minute)
   {
      MqlDateTime timeStruct;
      TimeToStruct(TimeLocal(), timeStruct);
      hour = timeStruct.hour;
      minute = timeStruct.min;
   }
   
   // ================= GET CURRENT DATETIME STRUCT =================
   static MqlDateTime GetCurrentTimeStruct()
   {
      MqlDateTime timeStruct;
      TimeToStruct(TimeLocal(), timeStruct);
      return timeStruct;
   }
};

#endif