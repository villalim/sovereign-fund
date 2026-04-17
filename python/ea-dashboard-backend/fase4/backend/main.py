import sys
sys.path.insert(0, r'C:\Users\evila\ea-dashboard-backend\fase4')

from fastapi import FastAPI, WebSocket
from typing import List
import json

app = FastAPI()

items = []

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/items")
def get_items():
    return {"items": items}

@app.post("/items")
def add_item(item: dict):
    items.append(item)
    return {"message": "Item added", "item": item}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_text()
        await websocket.send_text(f"Echo: {data}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
