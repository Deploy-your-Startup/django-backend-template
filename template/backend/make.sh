#!/bin/bash

# Fail on the first failing command. Without this the script returns the exit
# code of the *last* line only, so a failing `ruff check` would be masked by a
# passing `ty check` and the CI gate would go green on a lint error.
set -e
cd "$(dirname "$0")"

# Combine the integration data from `test` with any E2E server data
# (`run_dev --coverage true`) into coverage/cobertura.xml, the file the shared
# pipeline reports (docs/architecture/0007).
write_coverage_report() {
    shopt -s nullglob
    local data=(coverage/integration.coverage coverage/e2e.coverage.*)
    shopt -u nullglob
    local existing=()
    for file in "${data[@]}"; do [ -f "$file" ] && existing+=("$file"); done
    if [ ${#existing[@]} -eq 0 ]; then
        echo "No coverage data in coverage/; run ./make.sh test first." >&2
        return 1
    fi
    rm -f coverage/all.coverage coverage/cobertura.xml
    uv run --group dev coverage combine --keep --quiet --data-file=coverage/all.coverage "${existing[@]}"
    uv run --group dev coverage xml --quiet --data-file=coverage/all.coverage -o coverage/cobertura.xml
    local total
    total="$(uv run --group dev coverage report --data-file=coverage/all.coverage --format=total)"
    echo "Coverage ${total}% (${#existing[@]} data files) written to coverage/cobertura.xml"
}

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
    coverage=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --port|--reload|--flush|--coverage|--database_url)
                if [ $# -lt 2 ]; then echo "Missing value for $1" >&2; exit 2; fi
                case "$1" in
                    --port) port="$2" ;;
                    --reload) reload="$2" ;;
                    --flush) flush="$2" ;;
                    --coverage) coverage="$2" ;;
                    --database_url) export DATABASE_URL="$2" ;;
                esac
                shift 2 ;;
            *) echo "Unknown option: $1" >&2; exit 2 ;;
        esac
    done
    uv run python manage.py migrate --noinput --settings project.settings
    if [ "$flush" == "true" ]; then
        uv run python manage.py flush --noinput --settings project.settings
    fi
    reload_flags=()
    if [ "$reload" == "true" ]; then
        reload_flags=(--reload --reload-include '*.html')
    fi
    runner=(python)
    if [ "$coverage" == "true" ]; then
        # E2E runs measure the server; data is written when uvicorn shuts down
        # on SIGTERM. Reload would measure only the supervisor process.
        mkdir -p coverage
        rm -f coverage/e2e.coverage.*
        runner=(--group dev coverage run --parallel-mode --data-file=coverage/e2e.coverage)
    fi
    exec uv run "${runner[@]}" -m uvicorn project.asgi:app --host "0.0.0.0" --port "$port" "${reload_flags[@]}"
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
    mkdir -p coverage
    rm -f coverage/integration.coverage
    DJANGO_SETTINGS_MODULE=project.settings COVERAGE_FILE=coverage/integration.coverage \
        uv run python -m pytest --reuse-db --create-db -v --cov --cov-report= "$@"
    write_coverage_report
fi

if [ "${1:-}" == "coverage" ]; then
    write_coverage_report
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

    # make.sh already changed into its own directory; "$0" may be relative.
    script_dir="$(pwd)"
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
