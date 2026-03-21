import json
import os
import subprocess
import sys
import time

import docker
import psycopg


def start_db_and_get_url(
    db_name: str = "django_db", database_url_name: str = "DATABASE_URL"
) -> str:
    if os.getenv(database_url_name):
        return ""

    context_str = subprocess.check_output(
        ["docker", "context", "ls", "--format", "json"]
    ).strip()
    context_json = json.loads(context_str)

    base_url = ""
    for context in context_json:
        if context.get("Current"):
            base_url = context["DockerEndpoint"]
            break

    host = "localhost"
    if "@" in base_url:
        _, host = base_url.split("@", 1)

    client = docker.client.DockerClient(base_url=base_url)

    try:
        container = client.containers.get(db_name)
        container.reload()
        if container.status == "exited":
            container.start()
    except Exception:
        print(f"Can't get container with name {db_name}, creating new one...")
        container = client.containers.run(
            image="postgres:17",
            name=db_name,
            environment={
                "POSTGRES_USER": "admin",
                "POSTGRES_HOST_AUTH_METHOD": "trust",
                "POSTGRES_DB": db_name,
            },
            ports={"5432/tcp": None},
            detach=True,
        )

    print(f"Waiting for ports of database {db_name} to be available")
    port_dict = container.attrs["NetworkSettings"]["Ports"]
    while not port_dict:
        dot_waiting_animation()
        container.reload()
        port_dict = container.attrs["NetworkSettings"]["Ports"]
    sys.stdout.write("\n")

    print(f"Waiting for database {db_name} to be available")
    while True:
        dot_waiting_animation()

        container.reload()
        port_dict = container.attrs["NetworkSettings"]["Ports"]
        port = port_dict["5432/tcp"][0]["HostPort"]

        try:
            with psycopg.connect(
                dbname=db_name,
                user="admin",
                password="admin",
                host=host,
                port=port,
            ):
                break
        except Exception:
            pass

    sys.stdout.write("\n")
    return f"postgres://admin:admin@{host}:{port}/{db_name}"


def dot_waiting_animation() -> None:
    sys.stdout.write(".")
    sys.stdout.flush()
    time.sleep(1)
