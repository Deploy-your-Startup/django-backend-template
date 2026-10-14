"""Public legal pages; configuration is operator-owned, plain text, never HTML."""

import json
from pathlib import Path

from django.http import HttpRequest, HttpResponse
from django.shortcuts import render


def legal_page(request: HttpRequest, page: str = "impressum") -> HttpResponse:
    policy = json.loads(Path(__file__).with_name("site-policy.json").read_text())
    is_ready = policy.get("reviewed") is True and all(
        isinstance(policy.get(field), str) and policy[field].strip()
        for field in (
            "operatorName",
            "operatorAddress",
            "contactEmail",
            "privacyNotice",
        )
    )
    return render(
        request, "legal.html", {"policy": policy, "is_ready": is_ready, "page": page}
    )
