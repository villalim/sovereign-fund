#ifndef __ZEROMQ_COMMAND_LISTENER_MQH__
#define __ZEROMQ_COMMAND_LISTENER_MQH__

#include <zmq/zmq.mqh>
#include "Logger.mqh"
#include "JSONParser.mqh"

//+------------------------------------------------------------------+
//| ZeroMQCommandListener.mqh                                        |
//| Gerencia recebimento de comandos via ZeroMQ (SUB socket)         |
//+------------------------------------------------------------------+


// Command Structure
struct CommandData
{
   string command_id;      // UUID do comando
   string command_type;    // START_STRATEGY, STOP_STRATEGY, etc
   string strategy;        // Nome da estratégia
   string payload;         // JSON com dados adicionais
   datetime received_at;
};

// CZeroMQCommandListener class
class CZeroMQCommandListener
{
private:
   // ZeroMQ Context e Socket
   void* m_context;
   void* m_socket;   
   // Configurações
   string m_endpoint;      // "tcp://127.0.0.1:5556"
   string m_subscription_filter;  // Filter para SUB socket   
   // Status
   bool m_connected;
   bool m_enabled;   
   // Logger
   CLogger* m_logger;   
   // Stats
   int m_commands_received;
   int m_commands_failed;   
   // Command queue (simples array)
   CommandData m_pending_commands[];

public:
   //--- Constructor / Destructor
   CZeroMQCommandListener();
   ~CZeroMQCommandListener();
   
   //--- Initialize / Deinitialize
   bool Initialize(string endpoint, string filter = "");
   void Deinitialize();
   
   //--- Configuration
   void SetLogger(CLogger* logger) { m_logger = logger; }
   
   //--- Control
   void Enable() { m_enabled = true; }
   void Disable() { m_enabled = false; }
   bool IsConnected() { return m_connected; }
   
   //--- Command Processing
   bool CheckPendingCommands();
   bool GetNextCommand(CommandData& cmd);
   int GetPendingCommandCount();
   
   //--- Statistics
   int GetCommandsReceived() { return m_commands_received; }
   int GetCommandsFailed() { return m_commands_failed; }
   void ResetStats() { m_commands_received = 0; m_commands_failed = 0; }
};

// Constructor
CZeroMQCommandListener::CZeroMQCommandListener()
   : m_context(NULL),
     m_socket(NULL),
     m_endpoint("tcp://127.0.0.1:5556"),
     m_subscription_filter(""),
     m_connected(false),
     m_enabled(false),
     m_logger(NULL),
     m_commands_received(0),
     m_commands_failed(0)
{
   ArrayResize(m_pending_commands, 0);
}

// Destructor
CZeroMQCommandListener::~CZeroMQCommandListener()
{
   Deinitialize();
}

// Initialize - Cria socket SUB
bool CZeroMQCommandListener::Initialize(string endpoint, string filter = "")
{
   if(m_socket != NULL)
      Deinitialize();
   
   m_endpoint = endpoint;
   m_subscription_filter = filter;
   
   // Usar contexto existente ou criar novo
   m_context = zmq_ctx_new();
   if(m_context == NULL)
   {
      if(m_logger) m_logger->LogEvent("ZMQ_CMD", "ERROR", "Failed to create ZeroMQ context");
      return false;
   }
   
   // Criar SUB socket
   m_socket = zmq_socket(m_context, ZMQ_SUB);
   if(m_socket == NULL)
   {
      if(m_logger) m_logger->LogEvent("ZMQ_CMD", "ERROR", "Failed to create ZeroMQ socket");
      zmq_ctx_destroy(m_context);
      m_context = NULL;
      return false;
   }
   
   // Conectar ao backend
   if(zmq_connect(m_socket, endpoint) != 0)
   {
      if(m_logger) m_logger->LogEvent("ZMQ_CMD", "ERROR", "Failed to connect to " + endpoint);
      zmq_close(m_socket);
      zmq_ctx_destroy(m_context);
      m_socket = NULL;
      m_context = NULL;
      return false;
   }
   
   // Subscribe com filter
   if(StringLen(filter) > 0)
   {
      zmq_setsockopt(m_socket, ZMQ_SUBSCRIBE, filter);
   }
   else
   {
      // Subscribe para tudo
      zmq_setsockopt(m_socket, ZMQ_SUBSCRIBE, "");
   }
   
   // Configurar timeout para não bloquear
   int timeout = 100; // 100ms
   zmq_setsockopt(m_socket, ZMQ_RCVTIMEO, timeout);
   
   m_connected = true;
   if(m_logger) m_logger->LogEvent("ZMQ_CMD", "INFO", "ZeroMQ Command Listener initialized - Endpoint: " + endpoint);
   
   return true;
}

// Deinitialize - Fecha socket
void CZeroMQCommandListener::Deinitialize()
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
   
   ArrayResize(m_pending_commands, 0);
   m_connected = false;
   if(m_logger) m_logger->LogEvent("ZMQ_CMD", "INFO", "ZeroMQ Command Listener deinitialized");
}

// CheckPendingCommands - Verifica se há comandos novos
bool CZeroMQCommandListener::CheckPendingCommands()
{
   if(!m_enabled || !m_connected || m_socket == NULL)
      return false;
   
   char buffer[4096];
   int size = zmq_recv(m_socket, buffer, sizeof(buffer) - 1, ZMQ_DONTWAIT);
   
   if(size == -1)
   {
      // Timeout ou erro - normal em modo DONTWAIT
      return false;
   }
   
   if(size <= 0)
   {
      m_commands_failed++;
      return false;
   }
   
   // Converter buffer para string
   buffer[size] = '\0';
   string json_str = CharArrayToString(buffer);
   
   // Parse do JSON (simplificado - você pode melhorar com JSONParser)
   // Por enquanto, apenas adiciona à fila
   CommandData cmd;
   cmd.command_id = "cmd_" + IntegerToString(m_commands_received);
   cmd.command_type = "UNKNOWN";
   cmd.strategy = "";
   cmd.payload = json_str;
   cmd.received_at = TimeCurrent();
   
   // Adicionar à fila
   int size_before = ArraySize(m_pending_commands);
   ArrayResize(m_pending_commands, size_before + 1);
   m_pending_commands[size_before] = cmd;
   
   m_commands_received++;
   
   if(m_logger) m_logger->LogDebug("ZMQ_CMD", "COMMAND_RECEIVED", "Payload: " + json_str);
   
   return true;
}

// GetNextCommand - Retorna próximo comando da fila
bool CZeroMQCommandListener::GetNextCommand(CommandData& cmd)
{
   if(ArraySize(m_pending_commands) == 0)
      return false;
   
   cmd = m_pending_commands[0];
   
   // Remove da fila (shift)
   for(int i = 0; i < ArraySize(m_pending_commands) - 1; i++)
   {
      m_pending_commands[i] = m_pending_commands[i + 1];
   }
   
   ArrayResize(m_pending_commands, ArraySize(m_pending_commands) - 1);
   
   return true;
}

// GetPendingCommandCount - Retorna quantidade de comandos pendentes
int CZeroMQCommandListener::GetPendingCommandCount()
{
   return ArraySize(m_pending_commands);
}

#endif