#property copyright "Test Suite - Evilazio Lima"
#property version   "1.0"

#include "../Core/Logger.mqh"
#include "../Core/HeartbeatHTTP.mqh"


/////// Confirmar que o heartbeat é enviado a cada 5 segundos
// ================= TESTE 1: Intervalo de Heartbeat =================

void OnInit()
{
   Print("=== TESTE 1: Heartbeat Interval ===");
   
   CLogger logger;
   logger.Init();
   
   CHeartbeatHTTP heartbeat;
   heartbeat.SetLogger(&logger);
   heartbeat.SetHeartbeatInterval(5);  // 5 segundos
   heartbeat.SetInstanceId("TEST_INSTANCE");
   heartbeat.SetAccountNumber("12345");
   heartbeat.Enable();
   
   Print("Heartbeat configurado para 5 segundos");
   Print("ShouldSendHeartbeat (T=0): " + (heartbeat.ShouldSendHeartbeat() ? "TRUE" : "FALSE"));
   
   // Simular espera de 3 segundos
   Sleep(3000);
   Print("ShouldSendHeartbeat (T=3s): " + (heartbeat.ShouldSendHeartbeat() ? "TRUE" : "FALSE") + " [Esperado: FALSE]");
   
   // Simular espera de 2 segundos mais (total 5)
   Sleep(2000);
   Print("ShouldSendHeartbeat (T=5s): " + (heartbeat.ShouldSendHeartbeat() ? "TRUE" : "FALSE") + " [Esperado: TRUE]");
}

void OnTick()
{
}

void OnDeinit(const int reason)
{
   Print("=== TESTE 1 FINALIZADO ===");
}