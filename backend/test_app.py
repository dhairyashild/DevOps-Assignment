import pytest
from flask import Flask
from app import app  # Points to your app/app.py

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert b"OK" in response.data
    print("✅ /health PASSED")

def test_message_endpoint(client):
    response = client.get('/api/message')
    assert response.status_code == 200  
    assert b"message" in response.data or b"Hello" in response.data
    print("✅ /api/message PASSED")
