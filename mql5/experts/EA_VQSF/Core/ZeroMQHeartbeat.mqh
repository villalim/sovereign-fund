#ifndef __ZEROMQ_HEARTBEAT_MQH__
#define __ZEROMQ_HEARTBEAT_MQH__

#include <zmq/zmq.mqh>
#include "Logger.mqh"
#include "JSONParser.mqh"

//+------------------------------------------------------------------+
//| Gerencia envio de heartbeats via ZeroMQ (PUSH socket)            |
//| Intervalo: 5 segundos                                            |
//+------------------------------------------------------------------+

class CZeroMQHeartbeat
{
private:
   // ZeroMQ Context e Socket
   void* m_context;
   void* m_socket;
   
   // Configurações
   string m_endpoint;           // "tcp://127.0.0.1:5555"
   int m_heartbeat_interval_ms; // 5000 ms = 5 segundos
   datetime m_last_heartbeat_time;
   
   // Instância de EA
   string m_instance_id;        // "ea_001"
   string m_account_number;
   string m_server_name;
   string m_ea_version;
   
   // Status
   bool m_connected;
   bool m_enabled;
   
   // Logger
   CLogger* m_logger;
   
   // Stats
   int m_heartbeats_sent;
   int m_heartbeats_failed;

public:
   //--- Constructor / Destructor
   CZeroMQHeartbeat();
   ~CZeroMQHeartbeat();
   
   //--- Initialize / Deinitialize
   bool Initialize(string endpoint, int interval_ms);
   void Deinitialize();
   
   //--- Configuration
   void SetLogger(CLogger* logger) { m_logger = logger; }
   void SetInstanceId(string id) { m_instance_id = id; }
   void SetAccountNumber(string account) { m_account_number = account; }
   void SetServerName(string server) { m_server_name = server; }
   void SetEAVersion(string version) { m_ea_version = version; }
   
   //--- Control
   void Enable() { m_enabled = true; }
   void Disable() { m_enabled = false; }
   bool IsConnected() { return m_connected; }
   
   //--- Heartbeat Processing
   bool ShouldSendHeartbeat();
   bool SendHeartbeat(double balance, double equity, double margin_level,
                      string primary_symbol, double ask, double bid);
   
   //--- Statistics
   int GetHeartbeatsSent() { return m_heartbeats_sent; }
   int GetHeartbeatsFailed() { return m_heartbeats_failed; }
   void ResetStats() { m_heartbeats_sent = 0; m_heartbeats_failed = 0; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+

CZeroMQHeartbeat::CZeroMQHeartbeat()
   : m_context(NULL),
     m_socket(NULL),
     m_endpoint("tcp://127.0.0.1:5555"),
     m_heartbeat_interval_ms(5000),
     m_last_heartbeat_time(0),
     m_instance_id(""),
     m_account_number(""),
     m_server_name(""),
     m_ea_version("5.0.0"),
     m_connected(false),
     m_enabled(false),
     m_logger(NULL),
     m_heartbeats_sent(0),
     m_heartbeats_failed(0)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+

CZeroMQHeartbeat::~CZeroMQHeartbeat()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize - Cria contexto e socket ZeroMQ                      |
//+------------------------------------------------------------------+

bool CZeroMQHeartbeat::Initialize(string endpoint, int interval_ms)
{
   if(m_socket != NULL)
      Deinitialize();
   
   m_endpoint = endpoint;
   m_heartbeat_interval_ms = interval_ms;
   
   // Criar contexto ZeroMQ
   m_context = zmq_ctx_new();
   if(m_context == NULL)
   {
      if(m_logger) m_logger->LogEvent("ZMQ_HB", "ERROR", "Failed to create ZeroMQ context");
      return false;
   }
   
   // Criar PUSH socket
   m_socket = zmq_socket(m_context, ZMQ_PUSH);
   if(m_socket == NULL)
   {
      if(m_logger) m_logger->LogEvent("ZMQ_HB", "ERROR", "Failed to create ZeroMQ socket");
      zmq_ctx_destroy(m_context);
      m_context = NULL;
      return false;
   }
   
   // Conectar ao backend
   if(zmq_connect(m_socket, endpoint) != 0)
   {
      if(m_logger) m_logger->LogEvent("ZMQ_HB", "ERROR", "Failed to connect to " + endpoint);
      zmq_close(m_socket);
      zmq_ctx_destroy(m_context);
      m_socket = NULL;
      m_context = NULL;
      return false;
   }
   
   m_connected = true;
   if(m_logger) m_logger->LogEvent("ZMQ_HB", "INFO", "ZeroMQ Heartbeat initialized - Endpoint: " + endpoint);
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize - Fecha socket e contexto                           |
//+------------------------------------------------------------------+

void CZeroMQHeartbeat::Deinitialize()
{
   if(m_socket != NULL)
   {
      zmq_close(m_socket);
      m_socket = NULL;
   }
   
   if(m_context != NULL)
   {
      zmq_ctx_destroy(m_context);
      m_context = NULL;
   }
   
   m_connected = false;
   if(m_logger) m_logger->LogEvent("ZMQ_HB", "INFO", "ZeroMQ Heartbeat deinitialized");
}

//+------------------------------------------------------------------+
//| ShouldSendHeartbeat - Verifica se é hora de enviar heartbeat    |
//+------------------------------------------------------------------+

bool CZeroMQHeartbeat::ShouldSendHeartbeat()
{
   if(!m_enabled || !m_connected)
      return false;
   
   datetime current_time = TimeCurrent();
   int elapsed_ms = (int)((current_time - m_last_heartbeat_time) * 1000);
   
   return (elapsed_ms >= m_heartbeat_interval_ms);
}

//+------------------------------------------------------------------+
//| SendHeartbeat - Envia heartbeat JSON para backend                |
//+------------------------------------------------------------------+

bool CZeroMQHeartbeat::SendHeartbeat(double balance, double equity, double margin_level,
                                      string primary_symbol, double ask, double bid)
{
   if(!m_enabled || !m_connected)
      return false;
   
   // Construir JSON do heartbeat
   string json = "{";
   json += "\"instance_id\":\"" + m_instance_id + "\",";
   json += "\"account_number\":" + m_account_number + ",";
   json += "\"server_name\":\"" + m_server_name + "\",";
   json += "\"heartbeat_time\":\"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\",";
   json += "\"timestamp_unix\":" + IntegerToString((int)TimeCurrent()) + ",";
   json += "\"balance\":" + DoubleToString(balance, 2) + ",";
   json += "\"equity\":" + DoubleToString(equity, 2) + ",";
   json += "\"free_margin\":" + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2) + ",";
   json += "\"margin_used\":" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2) + ",";
   json += "\"margin_level\":" + DoubleToString(margin_level, 2) + ",";
   json += "\"primary_symbol\":\"" + primary_symbol + "\",";
   json += "\"ask\":" + DoubleToString(ask, _Digits) + ",";
   json += "\"bid\":" + DoubleToString(bid, _Digits) + ",";
   json += "\"spread\":" + IntegerToString((int)(ask - bid) * 10000) + ",";
   json += "\"is_connected\":true,";
   json += "\"ea_version\":\"" + m_ea_version + "\",";
   json += "\"open_trades\":[],";
   json += "\"strategies\":[],";
   json += "\"daily_stats\":{\"trades_count\":0,\"trades_won\":0,\"trades_lost\":0,\"net_profit\":0.0}";
   json += "}";
   
   // Enviar para backend
   int size = StringLen(json);
   int sent = zmq_send(m_socket, json, size, ZMQ_DONTWAIT);
   
   if(sent == size)
   {
      m_last_heartbeat_time = TimeCurrent();
      m_heartbeats_sent++;
      
      if(m_logger) m_logger->LogDebug("ZMQ_HB", "HEARTBEAT_SENT", "Instance: " + m_instance_id + " | Time: " + TimeToString(TimeCurrent()));
      
      return true;
   }
   else
   {
      m_heartbeats_failed++;
      
      if(m_logger) m_logger->LogEvent("ZMQ_HB", "ERROR", "Failed to send heartbeat - Error: " + IntegerToString(zmq_errno()));
      
      return false;
   }
}

#endif