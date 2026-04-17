from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.database.connection import get_db
from backend.services.crud import get_items, create_item
from pydantic import BaseModel

router = APIRouter()

class ItemCreate(BaseModel):
    name: str
    description: str

@router.get("/items/")
async def read_items(db: Session = Depends(get_db)):
    items = get_items(db)
    return items

@router.post("/items/")
async def create_new_item(item: ItemCreate, db: Session = Depends(get_db)):
    return create_item(db, item.name, item.description)
