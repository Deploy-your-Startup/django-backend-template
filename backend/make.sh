#!/bin/bash

if [ "$1" == "setup_local" ]; then
    echo "Install dependencies you need to run this project"
    echo "Install uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    uv tool install ruff@latest
fi

if [ "$1" == "run" ]; then
    echo "Running backend"
    uv run python manage.py collectstatic --noinput
    uv run python manage.py migrate --noinput --settings project.settings
    uv run python -m uvicorn project.asgi:app --host "0.0.0.0" --port 8000
fi

if [ "$1" == "run_dev" ]; then
    echo "Running backend with hot-reload"
    uv run python manage.py migrate --noinput --settings project.settings
    uv run python -m uvicorn project.asgi:app --host "0.0.0.0" --port 8000 --reload --reload-include "*.html"
fi

if [ "$1" == "migrate" ]; then
    echo "Running migrations"
    uv run python manage.py migrate --noinput --settings project.settings
fi

if [ "$1" == "makemigrations" ]; then
    echo "Creating migrations"
    uv run python manage.py makemigrations --settings project.settings
fi

if [ "$1" == "test" ]; then
    echo "Running tests"
    uv run python manage.py test --settings project.settings
fi

if [ "$1" == "format" ]; then
    echo "Format code and run ruff checks"
    uvx ruff format
    uvx ruff check --fix
fi
