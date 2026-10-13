# Browser tooling is separate from the small production Dockerfile.
FROM node:24-bookworm-slim AS node
FROM python:3.14-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
WORKDIR /workspace/e2e_tests
COPY e2e_tests/package*.json ./
RUN npm ci && npx playwright install --with-deps --only-shell chromium \
 && rm -rf /var/lib/apt/lists/* /root/.npm/_cacache
WORKDIR /workspace/backend
COPY backend/pyproject.toml backend/uv.lock backend/.python-version ./
RUN uv sync --locked
COPY backend/ ./
WORKDIR /workspace/e2e_tests
COPY e2e_tests/ ./
CMD ["./make.sh", "ci_e2e"]
