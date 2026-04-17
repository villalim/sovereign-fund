#property copyright "Test Suite - Evilazio Lima"
#property version   "1.0"

#include "../Core/Logger.mqh"
#include "../Core/HeartbeatHTTP.mqh"

//////  Confirmar que o payload contém todos os dados necessários.


void OnInit()
{
   Print("=== TESTE 2: Heartbeat Payload ===");
   
   CLogger logger;
   logger.Init();
   
   CHeartbeatHTTP heartbeat;
   heartbeat.SetLogger(&logger);
   heartbeat.SetHeartbeatInterval(5);
   heartbeat.SetInstanceId("TEST_EURUSD_12345");
   heartbeat.SetAccountNumber("12345");
   heartbeat.SetStrategyList("3BullGoDown,3BearGoDown,2Bear2BullGoUp");
   heartbeat.Enable();
   
   Print("=== Enviando heartbeat de teste ===");
   
   if(heartbeat.SendHeartbeat())
   {
      Print("✅ Heartbeat enviado com sucesso");
      Print("Verificar backend em: http://localhost:5000/heartbeat");
   }
   else
   {
      Print("❌ Falha ao enviar heartbeat");
   }
}

void OnTick()
{
}

void OnDeinit(const int reason)
{
   Print("=== TESTE 2 FINALIZADO ===");
}