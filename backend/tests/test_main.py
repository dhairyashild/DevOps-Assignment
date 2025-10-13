import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    """Test health check endpoint"""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "message" in data

def test_get_message():
    """Test message endpoint"""
    response = client.get("/api/message")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "You've successfully integrated the backend!"
    assert "message" in data

def test_cors_headers():
    """Test CORS headers are present"""
    response = client.options("/api/health", headers={"Origin": "http://localhost:3000"})
    assert response.status_code == 200
    assert "access-control-allow-origin" in response.headers
