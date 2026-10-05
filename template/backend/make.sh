#!/bin/bash

# Fail on the first failing command. Without this the script returns the exit
# code of the *last* line only, so a failing `ruff check` would be masked by a
# passing `ty check` and the CI gate would go green on a lint error.
set -e

if [ "${1:-}" == "setup_local" ]; then
    echo "Install project dependencies from the lock file"
    uv sync --locked
fi

if [ "${1:-}" == "run" ]; then
    echo "Running backend"
    uv run python manage.py collectstatic --noinput
    uv run python manage.py migrate --noinput --settings project.settings
    uv run python -m uvicorn project.asgi:app --host "0.0.0.0" --port 8000
fi

if [ "${1:-}" == "run_dev" ]; then
    shift
    port=8000
    reload=true
    flush=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --port|--reload|--flush|--database_url)
                if [ $# -lt 2 ]; then echo "Missing value for $1" >&2; exit 2; fi
                case "$1" in
                    --port) port="$2" ;;
                    --reload) reload="$2" ;;
                    --flush) flush="$2" ;;
                    --database_url) export DATABASE_URL="$2" ;;
                esac
                shift 2 ;;
            *) echo "Unknown option: $1" >&2; exit 2 ;;
        esac
    done
    cd "$(cd "$(dirname "$0")" && pwd)"
    uv run python manage.py migrate --noinput --settings project.settings
    if [ "$flush" == "true" ]; then
        uv run python manage.py flush --noinput --settings project.settings
    fi
    reload_flags=()
    if [ "$reload" == "true" ]; then
        reload_flags=(--reload --reload-include '*.html')
    fi
    exec uv run python -m uvicorn project.asgi:app --host "0.0.0.0" --port "$port" "${reload_flags[@]}"
fi

if [ "${1:-}" == "migrate" ]; then
    echo "Running migrations"
    uv run python manage.py migrate --noinput --settings project.settings
fi

if [ "${1:-}" == "makemigrations" ]; then
    echo "Creating migrations"
    uv run python manage.py makemigrations --settings project.settings
fi

if [ "${1:-}" == "dumpdata" ]; then
    uv run python manage.py dumpdata --natural-foreign --natural-primary --settings project.settings
fi

if [ "${1:-}" == "test" ]; then
    echo "Running tests"
    shift
    DJANGO_SETTINGS_MODULE=project.settings uv run python -m pytest --reuse-db --create-db -v "$@"
fi

if [ "${1:-}" == "format" ]; then
    echo "Formatting code and fixing what can be fixed..."
    # `uv run`, not `uvx`: uvx downloads the newest ruff on every invocation,
    # so two developers could lint against different rule sets. This uses the
    # version pinned in pyproject.toml.
    uv run --group dev ruff format
    uv run --group dev ruff check --fix
fi

if [ "${1:-}" == "lint" ]; then
    echo "Checking formatting, lint and types (no changes) — same as CI..."
    uv run --group dev ruff format --check
    uv run --group dev ruff check
    uv run --group dev ty check
fi

if [ "${1:-}" == "restore_local" ]; then
    # Restore latest production backup (DB + media) into the local dev DB.
    # Prerequisite: ./make.sh run_dev was started at least once
    # (docker_database_url spins up the local postgres container on settings import).
    shift
    while [ $# -gt 0 ]; do
        if [[ $1 == --* ]]; then
            if [[ "$1" == *=* ]]; then
                v="${1/--/}"
                declare "${v%%=*}"="${v#*=}"
            else
                v="${1/--/}"
                declare "$v"="$2"
                shift
            fi
        fi
        shift
    done

    script_dir="$(cd "$(dirname "$0")" && pwd)"
    project_slug="§§deploy_your_startup.project_name§§"
    project_db="${project_slug//-/_}_backend"
    backup_dir="${backup_dir:-$HOME/Backups/$project_slug}"
    clean="${clean:-true}"
    container_name="${container:-}"
    db_name="${db:-$project_db}"
    db_user="${user:-admin}"
    target_dir="${target:-$script_dir/media}"

    if [ -z "${db_file:-}" ]; then
        db_file=$(ls -1t "$backup_dir"/*-db-*.sql.gz "$backup_dir"/*/*-db-*.sql.gz 2>/dev/null | sed -n '1p')
    fi
    if [ -z "${media_file:-}" ]; then
        media_file=$(ls -1t "$backup_dir"/*-media-*.tar.gz "$backup_dir"/*/*-media-*.tar.gz 2>/dev/null | sed -n '1p')
    fi
    if [ -z "${db_file:-}" ] || [ ! -f "$db_file" ]; then
        echo "No database dump found in $backup_dir"
        echo "Run a backup first: cd ../deployment && ./make.sh backup --environment production"
        exit 1
    fi
    if [ -z "${media_file:-}" ] || [ ! -f "$media_file" ]; then
        echo "No media archive found in $backup_dir"
        exit 1
    fi
    if [ -z "$container_name" ]; then
        POSTGRES_DB="$db_name" docker compose --file "$script_dir/docker-compose.yml" \
            --project-name "$db_name" up --detach --wait db
        container_name=$(POSTGRES_DB="$db_name" docker compose --file "$script_dir/docker-compose.yml" \
            --project-name "$db_name" ps --quiet db)
    fi
    if [ "$(docker inspect --format '{{.State.Running}}' "$container_name")" != "true" ]; then
        echo "Container '$container_name' is not running."
        exit 1
    fi

    echo "Restoring database from: $(basename "$db_file")"
    if [ "$clean" == "true" ]; then
        docker exec "$container_name" psql -U "$db_user" -d "$db_name" -v ON_ERROR_STOP=1 \
            -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public AUTHORIZATION \"$db_user\"; GRANT ALL ON SCHEMA public TO \"$db_user\";"
    fi
    gunzip -c "$db_file" | docker exec -i "$container_name" psql -U "$db_user" -d "$db_name" -v ON_ERROR_STOP=1

    echo "Restoring media from: $(basename "$media_file")"
    if [ "$clean" == "true" ]; then
        rm -rf "$target_dir"
    fi
    mkdir -p "$target_dir"
    tar -xzf "$media_file" -C "$target_dir" --strip-components=1

    echo "Local restore completed."
fi
