from fastapi import FastAPI
from typing import List

app = FastAPI()

# Armazenamento em memória para testes mínimos
heartbeat_history: List[dict] = []
commands: List[dict] = []
command_responses: List[dict] = []
metrics: List[dict] = []

@app.post("/heartbeat")
async def receive_heartbeat(data: dict):
    """Recebe heartbeat e armazena no histórico."""
    heartbeat_history.append(data)
    return {"status": "received"}

@app.post("/command_response")
async def receive_command_response(data: dict):
    """Recebe resposta de comando."""
    command_responses.append(data)
    return {"status": "received"}

@app.post("/metrics")
async def receive_metrics(data: dict):
    """Recebe métricas."""
    metrics.append(data)
    return {"status": "received"}

@app.get("/heartbeat_history")
async def get_heartbeat_history():
    """Retorna o histórico de heartbeats."""
    return {"history": heartbeat_history}

@app.get("/commands")
async def get_commands():
    """Retorna a lista de comandos enviados."""
    return {"commands": commands}

@app.post("/send_command")
async def send_command(data: dict):
    """Envia comando para EA (simulado, apenas armazena para testes)."""
    commands.append(data)
    # Para testar o ciclo completo, pode simular resposta ou apenas confirmar envio
    return {"status": "sent", "command_id": len(commands)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)