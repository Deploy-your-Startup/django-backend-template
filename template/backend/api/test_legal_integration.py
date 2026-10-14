import json
from pathlib import Path

from django.test import SimpleTestCase


class LegalPagesTests(SimpleTestCase):
    def test_public_draft_pages_and_footer(self):
        # GIVEN an anonymous visitor and the real operator-owned configuration
        for url, title in (("/impressum", "Impressum"), ("/privacy", "Privacy policy")):
            # WHEN opening a legal page without authentication
            response = self.client.get(url)
            # THEN missing information is explicit, with both pages reachable
            self.assertContains(response, f"<h1>{title}</h1>", html=True)
            policy = json.loads(
                (Path(__file__).parents[1] / "project/site-policy.json").read_text()
            )
            is_ready = policy["reviewed"] is True and all(
                policy.get(field, "").strip()
                for field in (
                    "operatorName",
                    "operatorAddress",
                    "contactEmail",
                    "privacyNotice",
                )
            )
            if is_ready:
                self.assertNotContains(response, "Draft —")
            else:
                self.assertContains(response, "Draft —")
            self.assertContains(response, 'href="/impressum"')
            self.assertContains(response, 'href="/privacy"')

    def test_login_exposes_legal_links(self):
        # GIVEN a visitor without an admin session
        # WHEN opening the real admin login
        response = self.client.get("/admin/login/")
        # THEN legal information is available before login
        self.assertContains(response, 'href="/impressum"')
        self.assertContains(response, 'href="/privacy"')
