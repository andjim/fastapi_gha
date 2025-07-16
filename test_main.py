from .main import app
from fastapi.testclient import TestClient
from datetime import datetime

client = TestClient(app)

def test_main_date():
    response = client.get("/date")
    assert response.status_code == 200
    # Check if the server_time is in the expected format
    assert response.json().get("server_time",False) is not True
    # Validate the datetime format
    assert datetime.strptime(response.json()["server_time"], "%A,%B %d,%Y %H:%M:%S") is not None 