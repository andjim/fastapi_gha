from fastapi import FastAPI
from datetime import datetime

app = FastAPI()

@app.get("/date")
def index():
    return {"server_time":datetime.now().strftime("%A,%B %d,%Y %H:%M:%S")}
