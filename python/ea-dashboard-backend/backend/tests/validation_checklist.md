# 🧪 FASE 3.2: CHECKLIST DE VALIDAÇÃO

**Projeto:** EA_Main_VQSF v5.02  
**Data:** 15 de Abril de 2026  
**Responsável:** Evilazio Lima  

---

## ✅ TESTE 1: Compilação do EA

- [ ] EA_Main_VQSF_v1.mq5 compila sem erros
- [ ] HeartbeatHTTP.mqh compila sem erros
- [ ] CommandListener.mqh compila sem erros
- [ ] BridgeHTTP.mqh compila sem erros
- [ ] Todos os includes são encontrados corretamente

**Status:** ☐ PASSOU / ☐ FALHOU  
**Observações:** _________________________

---

## ✅ TESTE 2: Heartbeat HTTP - Intervalo de 5 segundos

**Objetivo:** Validar que heartbeat é enviado a cada 5 segundos, não mais frequentemente.

**Passos:**
1. [ ] Abrir MT5 e compilar EA_Main_VQSF_v1.mq5
2. [ ] Verificar no terminal: "Heartbeat enabled - Interval: 5s"
3. [ ] Esperar 3 segundos e observar logs
4. [ ] Esperar mais 2 segundos (total 5s)
5. [ ] Verificar log: "Heartbeat sent - Next in 5s"
6. [ ] Repetir 3 vezes para confirmar consistência

**Tempo esperado entre heartbeats:** 5 ± 0.5 segundos

**Resultados:**
- Heartbeat 1: _______ segundos
- Heartbeat 2: _______ segundos
- Heartbeat 3: _______ segundos

**Status:** ☐ PASSOU / ☐ FALHOU  
**Observações:** _________________________

---

## ✅ TESTE 3: Payload do Heartbeat

**Objetivo:** Validar que heartbeat contém todos os campos necessários.

**Verificar se payload contém:**
- [ ] timestamp (formato ISO 8601)
- [ ] timestamp_unix (integer)
- [ ] instance_id
- [ ] account_number
- [ ] account_name
- [ ] server_name
- [ ] symbol
- [ ] balance
- [ ] equity
- [ ] free_margin
- [ ] margin_used
- [ ] margin_level
- [ ] ask
- [ ] bid
- [ ] spread
- [ ] open_positions
- [ ] is_connected
- [ ] ea_version
- [ ] session_start_time
- [ ] strategies[] (array)
- [ ] open_trades[] (array)
- [ ] daily_stats[] (object)

**Exemplo de payload recebido:**
```json
{
  "timestamp": "2026-04-15T10:30:45",
  "instance_id": "EURUSD_12345",
  "balance": 10000.00,
  ...
}