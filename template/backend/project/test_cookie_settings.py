import os
import subprocess
import sys
from pathlib import Path
from unittest import TestCase


class ProductionCookieTests(TestCase):
    def test_production_enables_secure_session_and_csrf_cookies(self):
        # GIVEN a fresh process loading the production settings with an isolated database
        env = {
            **os.environ,
            "PRODUCTION": "1",
            "SECRET_KEY": "cookie-test-only",
            "DATABASE_URL": "postgresql://localhost/cookie_test",
            "SENTRY_DSN": "",
        }
        # WHEN Django checks the configured session and CSRF cookies
        result = subprocess.run(
            [sys.executable, "manage.py", "check", "--deploy", "--tag", "security"],
            cwd=Path(__file__).resolve().parents[1],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )
        # THEN neither insecure-cookie system check is reported
        self.assertNotIn("security.W012", result.stderr)
        self.assertNotIn("security.W016", result.stderr)
