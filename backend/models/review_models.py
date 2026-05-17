from pydantic import BaseModel
from typing import Optional

class ReviewFlagRequest(BaseModel):
    isFlagged: bool
