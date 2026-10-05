import { defineConfig, devices } from "@playwright/test";
import { basename, resolve } from "node:path";

const port = Number(process.env.E2E_APP_PORT || 8001);
const url = `http://127.0.0.1:${port}`;
const databaseName =
  process.env.E2E_DB_NAME || `${basename(resolve(".."))}_e2e`;

export default defineConfig({
  testDir: "./tests",
  workers: 1,
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  reporter: "list",
  use: { baseURL: url, trace: "on-first-retry" },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: `cd ../backend && ./make.sh run_dev --port ${port} --reload false --flush true`,
    url: `${url}/api/health`,
    env: {
      // Keep the test stack separate from the development database and port.
      LOCAL_DB_NAME: databaseName.replaceAll("-", "_"),
      POSTGRES_PORT: process.env.E2E_POSTGRES_PORT || "55432",
    },
    reuseExistingServer: false,
    timeout: 300_000,
  },
});
