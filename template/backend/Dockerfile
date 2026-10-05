# Base image: Python slim with UV
FROM python:3.14-slim AS builder

# Copy UV binaries from the official UV image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Install only project dependencies (transitive deps only) to leverage caching
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

# Copy application source code
COPY . /app

# Install the application (including its own setup) into the environment
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Test stage: include dev dependencies and run tests
FROM builder AS test

# Sync dev dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Default command for testing
CMD ["./make.sh", "test"]

# Runtime stage: reuse builder for lightweight production image
FROM builder AS final

# Default command to start the application
CMD ["./make.sh", "run"]
