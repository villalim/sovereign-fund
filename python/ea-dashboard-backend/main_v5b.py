from fastapi import FastAPI, WebSocket, HTTPException
from fastapi.responses import JSONResponse
import sqlite3
import uvicorn
import json

app = FastAPI()

# Função para conectar ao banco de dados
def get_db_connection():
    conn = sqlite3.connect('database.db')
    conn.row_factory = sqlite3.Row
    return conn

# Endpoint GET /instances
@app.get('/instances')
async def get_instances():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT id, name, status FROM instances')
    rows = cursor.fetchall()
    conn.close()
    # Retorna lista de dicionários, compatível com Pandas DataFrame
    instances = [dict(row) for row in rows]
    return instances

# Endpoint GET /heartbeat
@app.get('/heartbeat')
async def heartbeat():
    return {'status': 'alive'}

# Endpoint GET /health
@app.get('/health')
async def health():
    return {'status': 'healthy'}

# Endpoint GET /commands
@app.get('/commands')
async def get_commands():
    # Implementação básica, assumindo uma tabela commands
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM commands')
    rows = cursor.fetchall()
    conn.close()
    commands = [dict(row) for row in rows]
    return commands

# Endpoint GET /commands/{id}
@app.get('/commands/{id}')
async def get_command(id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM commands WHERE id = ?', (id,))
    row = cursor.fetchone()
    conn.close()
    if row:
        return dict(row)
    else:
        raise HTTPException(status_code=404, detail='Command not found')

# Endpoint POST /commands/response
@app.post('/commands/response')
async def post_command_response(data: dict):
    # Implementação básica para receber resposta
    return {'message': 'Response received', 'data': data}

# Endpoint WebSocket /ws
@app.websocket('/ws')
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f'Echo: {data}')
    except Exception as e:
        print(f'WebSocket error: {e}')

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=8000)