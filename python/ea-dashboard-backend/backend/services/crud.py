from sqlalchemy.orm import Session
from backend.models.item import Item
from backend.database.connection import SessionLocal

def get_items(db: Session):
    return db.query(Item).all()

def create_item(db: Session, name: str, description: str):
    db_item = Item(name=name, description=description)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item
