import os
import subprocess
from pathlib import Path

COMPOSE_FILE = Path(__file__).resolve().parent.parent / "docker-compose.yml"


def start_db_and_get_url(
    db_name: str = "django_db", database_url_name: str = "DATABASE_URL"
) -> str:
    """Bring up the local Postgres from docker-compose.yml and return its URL.

    Called from settings.py, so a database is there whatever starts Django -
    make.sh, pytest, or the run button in an IDE - without anyone having to
    remember `docker compose up` first.

    Does nothing when the database is configured explicitly, which is how
    production and CI run: they set DATABASE_URL and never see Docker.
    """
    if os.getenv(database_url_name):
        return ""

    user = os.getenv("POSTGRES_USER", "admin")
    password = os.getenv("POSTGRES_PASSWORD", "admin")
    port = os.getenv("POSTGRES_PORT", "5432")

    # The project name keeps stacks apart: the e2e database is a different
    # container and a different volume from the development one, so tests can
    # never write into data you care about.
    subprocess.run(
        [
            "docker",
            "compose",
            "--file",
            str(COMPOSE_FILE),
            "--project-name",
            db_name,
            "up",
            "--detach",
            "--wait",
            "db",
        ],
        check=True,
        env={
            **os.environ,
            "POSTGRES_DB": db_name,
            "POSTGRES_USER": user,
            "POSTGRES_PASSWORD": password,
            "POSTGRES_PORT": port,
        },
    )

    return f"postgres://{user}:{password}@127.0.0.1:{port}/{db_name}"
