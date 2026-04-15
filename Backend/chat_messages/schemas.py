from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ChatMessageSchema(BaseModel):
    user_id: Optional[int] = None
    plant_id: Optional[int] = None
    message_text: Optional[str] = None
    sender: Optional[str] = None
    timestamp: Optional[datetime] = None
