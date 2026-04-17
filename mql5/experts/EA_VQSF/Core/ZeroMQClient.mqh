#ifndef __ZEROMQ_CLIENT_H__
#define __ZEROMQ_CLIENT_H__

#include "Logger.mqh"
#include "JSONParser.mqh"

// ZeroMQClient.mqh - Wrapper para comunicacao com Backend Python
// Usa HTTP como transporte (backend converte para ZeroMQ)

// Enum para tipos de comando
enum ENUM_COMMAND_TYPE
{
   COMMAND_START_STRATEGY,
   COMMAND_STOP_STRATEGY,
   COMMAND_CLOSE_ALL_TRADES,
   COMMAND_ADJUST_PARAMETER,
   COMMAND_SET_DAILY_LIMIT,
   COMMAND_PAUSE_TRADING,
   COMMAND_UPDATE_TRAILING_STOP,
   COMMAND_GET_CONFIG
};

// Struct para comando
struct SCommand
{
   string command_id;
   ENUM_COMMAND_TYPE command_type;
   string strategy;
   string payload;  // JSON
   datetime issued_at;
   int priority;    // 1=baixa, 5=alta
};

// Struct para heartbeat
struct SHeartbeat
{
   string instance_id;
   long account_number;
   string account_name;
   string server_name;
   datetime heartbeat_time;
   long timestamp_unix;
   double balance;
   double equity;
   double free_margin;
   double margin_used;
   double margin_level;
   string primary_symbol;
   double ask;
   double bid;
   double spread;
   bool is_connected;
   string ea_version;
};

// Classe CZeroMQClient
class CZeroMQClient
{
private:
   CLogger* m_logger;
   string m_server_url;
   string m_instance_id;
   long m_account_number;
   string m_account_name;
   
   SCommand m_command_queue[100];
   int m_queue_count;
   
   datetime m_last_heartbeat_sent;
   int m_heartbeat_interval_sec;
   
   bool m_connected;
   
public:
   // Constructor
   CZeroMQClient();
   ~CZeroMQClient();
   
   // Setup
   void SetLogger(CLogger* logger) { m_logger = logger; }
   void SetServerUrl(string url) { m_server_url = url; }
   void SetInstanceId(string id) { m_instance_id = id; }
   void SetAccountNumber(long account) { m_account_number = account; }
   void SetAccountName(string name) { m_account_name = name; }
   void SetHeartbeatInterval(int seconds) { m_heartbeat_interval_sec = seconds; }
   
   // Connection
   bool Connect();
   void Disconnect();
   bool IsConnected() { return m_connected; }   
   // Heartbeat
   bool SendHeartbeat(double balance, double equity, double margin_level, 
                      int open_trades, string strategies_json);
   bool ShouldSendHeartbeat();   
   // Commands
   bool QueueCommand(ENUM_COMMAND_TYPE cmd_type, string strategy, string payload);
   bool ProcessCommandQueue();
   int GetQueuedCommandCount() { return m_queue_count; }   
   // Utility
   string CommandTypeToString(ENUM_COMMAND_TYPE cmd);
   string GenerateCommandId();
};

// Constructor
CZeroMQClient::CZeroMQClient()
{
   m_logger = NULL;
   m_server_url = "http://localhost:8000";
   m_instance_id = "";
   m_account_number = 0;
   m_account_name = "";
   m_queue_count = 0;
   m_last_heartbeat_sent = 0;
   m_heartbeat_interval_sec = 5;
   m_connected = false;
}

// Destructor
CZeroMQClient::~CZeroMQClient()
{
   if(m_connected)
      Disconnect();
}

// Conectar ao servidor
bool CZeroMQClient::Connect()
{
   if(m_logger)
      m_logger->LogDebug("ZMQ", "CONNECT", "Attempting to connect to: " + m_server_url);
   
   // Teste de conexão simples (health check)
   string headers = "User-Agent: EA_VQSF\r\n";
   char response[];
   int http_code = WebRequest(
      "GET",
      m_server_url + "/health",
      headers,
      NULL,
      5000,
      response,
      NULL
   );
   
   if(http_code == 200)
   {
      m_connected = true;
      if(m_logger)
         m_logger->LogEvent("ZMQ", "CONNECT", "Connected to backend at " + m_server_url);
      return true;
   }
   else
   {
      m_connected = false;
      if(m_logger)
         m_logger->LogEvent("ZMQ", "ERROR", "Failed to connect. HTTP Code: " + IntegerToString(http_code));
      return false;
   }
}

// Desconectar
void CZeroMQClient::Disconnect()
{
   m_connected = false;
   if(m_logger)
      m_logger->LogEvent("ZMQ", "DISCONNECT", "Disconnected from backend");
}

// Verificar se deve enviar heartbeat
bool CZeroMQClient::ShouldSendHeartbeat()
{
   datetime now = TimeCurrent();
   int seconds_passed = (int)(now - m_last_heartbeat_sent);
   
   if(seconds_passed >= m_heartbeat_interval_sec)
   {
      return true;
   }
   
   return false;
}

// Enviar heartbeat
bool CZeroMQClient::SendHeartbeat(double balance, double equity, double margin_level,
                                   int open_trades, string strategies_json)
{
   if(!m_connected)
      return false;
   
   if(!ShouldSendHeartbeat())
      return true;  // Ainda não é hora
   
   // Montar JSON do heartbeat
   string json = "{";
   json += "\"instance_id\":\"" + m_instance_id + "\",";
   json += "\"account_number\":" + IntegerToString(m_account_number) + ",";
   json += "\"account_name\":\"" + m_account_name + "\",";
   json += "\"server_name\":\"" + AccountInfoString(ACCOUNT_SERVER) + "\",";
   json += "\"heartbeat_time\":\"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\",";
   json += "\"timestamp_unix\":" + IntegerToString((int)TimeCurrent()) + ",";
   json += "\"balance\":" + DoubleToString(balance, 2) + ",";
   json += "\"equity\":" + DoubleToString(equity, 2) + ",";
   json += "\"margin_level\":" + DoubleToString(margin_level, 2) + ",";
   json += "\"open_trades\":" + IntegerToString(open_trades) + ",";
   json += "\"is_connected\":true,";
   json += "\"ea_version\":\"5.02\",";
   json += "\"strategies\":" + strategies_json;
   json += "}";
   
   // Enviar heartbeat
   string headers = "Content-Type: application/json\r\nUser-Agent: EA_VQSF\r\n";
   char response[];
   
   int http_code = WebRequest(
      "POST",
      m_server_url + "/api/heartbeat/receive",
      headers,
      (uchar*)json,
      5000,
      response,
      NULL
   );
   
   if(http_code == 200)
   {
      m_last_heartbeat_sent = TimeCurrent();
      if(m_logger)
         m_logger->LogDebug("ZMQ", "HEARTBEAT", "Heartbeat sent successfully");
      return true;
   }
   else
   {
      if(m_logger)
         m_logger->LogEvent("ZMQ", "ERROR", "Heartbeat send failed. HTTP Code: " + IntegerToString(http_code));
      return false;
   }
}

// Enfileirar comando
bool CZeroMQClient::QueueCommand(ENUM_COMMAND_TYPE cmd_type, string strategy, string payload)
{
   if(m_queue_count >= 100)
   {
      if(m_logger)
         m_logger->LogEvent("ZMQ", "ERROR", "Command queue is full");
      return false;
   }
   
   SCommand cmd;
   cmd.command_id = GenerateCommandId();
   cmd.command_type = cmd_type;
   cmd.strategy = strategy;
   cmd.payload = payload;
   cmd.issued_at = TimeCurrent();
   cmd.priority = 1;
   
   m_command_queue[m_queue_count] = cmd;
   m_queue_count++;
   
   if(m_logger)
      m_logger->LogDebug("ZMQ", "QUEUE", "Command queued: " + CommandTypeToString(cmd_type) + 
                         " for " + strategy);
   
   return true;
}

// Processar fila de comandos
bool CZeroMQClient::ProcessCommandQueue()
{
   if(m_queue_count == 0 || !m_connected)
      return true;
   
   // Processar primeiro comando da fila
   SCommand cmd = m_command_queue[0];
   
   // Montar JSON do comando
   string json = "{";
   json += "\"command_id\":\"" + cmd.command_id + "\",";
   json += "\"command_type\":\"" + CommandTypeToString(cmd.command_type) + "\",";
   json += "\"strategy\":\"" + cmd.strategy + "\",";
   json += "\"payload\":" + cmd.payload + ",";
   json += "\"issued_at\":\"" + TimeToString(cmd.issued_at) + "\",";
   json += "\"priority\":" + IntegerToString(cmd.priority);
   json += "}";
   
   // Enviar comando
   string headers = "Content-Type: application/json\r\nUser-Agent: EA_VQSF\r\n";
   char response[];
   
   int http_code = WebRequest(
      "POST",
      m_server_url + "/api/commands/execute",
      headers,
      (uchar*)json,
      5000,
      response,
      NULL
   );
   
   if(http_code == 200 || http_code == 202)
   {
      if(m_logger)
         m_logger->LogEvent("ZMQ", "COMMAND", "Command sent: " + CommandTypeToString(cmd.command_type));
      
      // Remover da fila
      for(int i = 0; i < m_queue_count - 1; i++)
      {
         m_command_queue[i] = m_command_queue[i + 1];
      }
      m_queue_count--;
      
      return true;
   }
   else
   {
      if(m_logger)
         m_logger->LogEvent("ZMQ", "ERROR", "Command send failed. HTTP Code: " + IntegerToString(http_code));
      return false;
   }
}

// Converter tipo de comando para string
string CZeroMQClient::CommandTypeToString(ENUM_COMMAND_TYPE cmd)
{
   switch(cmd)
   {
      case COMMAND_START_STRATEGY: return "START_STRATEGY";
      case COMMAND_STOP_STRATEGY: return "STOP_STRATEGY";
      case COMMAND_CLOSE_ALL_TRADES: return "CLOSE_ALL_TRADES";
      case COMMAND_ADJUST_PARAMETER: return "ADJUST_PARAMETER";
      case COMMAND_SET_DAILY_LIMIT: return "SET_DAILY_LIMIT";
      case COMMAND_PAUSE_TRADING: return "PAUSE_TRADING";
      case COMMAND_UPDATE_TRAILING_STOP: return "UPDATE_TRAILING_STOP";
      case COMMAND_GET_CONFIG: return "GET_CONFIG";
      default: return "UNKNOWN";
   }
}

// Gerar ID único para comando
string CZeroMQClient::GenerateCommandId()
{
   return "cmd_" + IntegerToString(m_account_number) + "_" + 
          IntegerToString((int)TimeCurrent()) + "_" + 
          IntegerToString(rand());
}

#endif