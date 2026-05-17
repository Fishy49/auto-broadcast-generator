import json
from dataclasses import dataclass, field
from typing import List

@dataclass
class Record:
    created_at: str = ""
    events: List[str] = field(default_factory=list)
    script_prompt: str = ""
    script: str = ""
    audio_file: str = ""
    error: str = ""
    
    FILE_PATH = "data.json"
    
    @classmethod
    def load(cls):
        try:
            with open(cls.FILE_PATH, 'r') as f:
                data = json.load(f)
                return cls(**data)
        except (FileNotFoundError, json.JSONDecodeError):
            return cls()
    
    def save(self):
        with open(self.FILE_PATH, 'w') as f:
            json.dump(self.__dict__, f, indent=2)
        return self