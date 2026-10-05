from django.test import TestCase
from fastapi.testclient import TestClient

from project.asgi import app


class HealthTests(TestCase):
    def test_health_endpoint(self):
        # GIVEN an empty database and the real ASGI application
        client = TestClient(app)

        # WHEN the API health endpoint is requested
        response = client.get("/api/health")

        # THEN the application responds successfully
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})
