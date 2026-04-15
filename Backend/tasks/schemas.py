from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TaskSchema(BaseModel):
    plant_id: Optional[int] = None
    description: Optional[str] = None
    created_at: Optional[datetime] = None
    due_date: Optional[datetime] = None


class TaskUpdateSchema(BaseModel):
    plant_id: Optional[int] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    completed_at: Optional[datetime] = None
