import json

from django.contrib import messages
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect


def is_htmx(request: HttpRequest) -> bool:
    """True if the request was sent by HTMX."""
    return bool(request.headers.get("HX-Request"))


def hx_trigger(
    events: dict | str,
    *,
    status: int = 204,
    headers: dict[str, str] | None = None,
) -> HttpResponse:
    """Response that fires client events via the HX-Trigger header."""
    trigger = events if isinstance(events, str) else json.dumps(events)
    return HttpResponse(
        status=status, headers={"HX-Trigger": trigger, **(headers or {})}
    )


def respond(
    request: HttpRequest,
    message: str,
    redirect_to: str,
    *,
    level: int = messages.SUCCESS,
    events: dict | None = None,
    **redirect_kwargs,
) -> HttpResponse:
    """Show a message: as toast for HTMX, otherwise as Django message + redirect."""
    if is_htmx(request):
        return hx_trigger({"showMessage": message, **(events or {})})
    messages.add_message(request, level, message)
    return redirect(redirect_to, **redirect_kwargs)
