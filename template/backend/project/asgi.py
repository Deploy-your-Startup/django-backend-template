import os

from django.apps import apps
from django.conf import settings

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "project.settings")
apps.populate(settings.INSTALLED_APPS)

import uvicorn  # noqa: E402
from django.core.asgi import get_asgi_application  # noqa: E402
from fastapi import FastAPI  # noqa: E402
from starlette.middleware.cors import CORSMiddleware  # noqa: E402
from starlette.staticfiles import StaticFiles  # noqa: E402

from api.routes import router  # noqa: E402


def get_application() -> FastAPI:
    app = FastAPI(title=settings.PROJECT_NAME, debug=settings.DEBUG)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(router, prefix="/api")

    if not settings.DEBUG:
        app.mount(
            settings.STATIC_URL,
            StaticFiles(directory=settings.STATIC_ROOT),
            name="static",
        )
        app.mount(
            settings.MEDIA_URL,
            StaticFiles(directory=settings.MEDIA_ROOT),
            name="media",
        )

    # django-stubs types ASGIHandler.__call__ slightly differently from
    # Starlette's ASGIApp protocol, so the two stub sets do not line up. The
    # handler is a valid ASGI app at runtime; this is a stubs mismatch only.
    app.mount("/", get_asgi_application())  # ty: ignore[invalid-argument-type]

    return app


app = get_application()

if __name__ == "__main__":
    uvicorn.run(
        "project.asgi:app",
        reload=True,
        host="0.0.0.0",
        port=8000,
        reload_dirs=str(settings.BASE_DIR),
    )
