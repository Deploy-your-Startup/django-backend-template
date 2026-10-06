import logging
import os
from pathlib import Path
from typing import Any

import dj_database_url
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration
from sentry_sdk.integrations.logging import LoggingIntegration

BASE_DIR = Path(__file__).resolve().parent.parent

PROJECT_NAME = "§§deploy_your_startup.project_name§§"

SECRET_KEY = os.environ["SECRET_KEY"] if os.getenv("PRODUCTION") else "local-dev-only"

DEBUG = not os.getenv("PRODUCTION")

ENVIRONMENT = os.getenv("ENVIRONMENT", "local")

ALLOWED_HOSTS = ["§§deploy_your_startup.base_domain§§"]

if DEBUG:
    ALLOWED_HOSTS.extend(["*"])


def generate_cors_allowed_origins(hosts):
    schemes = ["https://", "http://"]
    origins = []
    for host in hosts:
        if not host.startswith("http"):
            for scheme in schemes:
                origins.append(f"{scheme}{host}")
        else:
            origins.append(host)
    return origins


CORS_ALLOWED_ORIGINS = generate_cors_allowed_origins(ALLOWED_HOSTS)

LOCAL_DB_NAME = os.getenv("LOCAL_DB_NAME", PROJECT_NAME.replace("-", "_") + "_backend")

database_url_for_local_development = ""
if not os.getenv("DATABASE_URL"):
    import docker_database_url

    database_url_for_local_development = docker_database_url.start_db_and_get_url(
        db_name=LOCAL_DB_NAME,
        database_url_name="DATABASE_URL",
    )
default_database_url = os.getenv(
    "DATABASE_URL",
    database_url_for_local_development,
)

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django_bootstrap5",
    "api",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "project.urls"

TEMPLATES: list[dict[str, Any]] = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

if DEBUG:
    for template in TEMPLATES:
        template["APP_DIRS"] = False
        template["OPTIONS"]["loaders"] = [
            "django.template.loaders.filesystem.Loader",
            "django.template.loaders.app_directories.Loader",
        ]

WSGI_APPLICATION = "project.wsgi.application"

CSRF_TRUSTED_ORIGINS = [
    "https://§§deploy_your_startup.base_domain§§",
    "https://*.§§deploy_your_startup.base_domain§§",
]

DATABASES = {
    "default": dj_database_url.parse(default_database_url),
}

sentry_logging = LoggingIntegration(level=logging.INFO, event_level=logging.ERROR)
sentry_dsn = os.getenv("SENTRY_DSN", "")
if not DEBUG and sentry_dsn.startswith(("http://", "https://")):
    sentry_sdk.init(
        dsn=sentry_dsn,
        environment=ENVIRONMENT,
        integrations=[sentry_logging, DjangoIntegration()],
    )

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"
    },
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = os.path.join(BASE_DIR, "static")

MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

CACHE_URL = os.getenv("CACHE_URL", "redis://redis:6379/1")
if DEBUG:
    CACHE_URL = "redis://localhost:6379/1"

BOOTSTRAP5 = {
    "required_css_class": "required",
    "set_placeholder": False,
}
SECURE_REFERRER_POLICY = "strict-origin-when-cross-origin"
