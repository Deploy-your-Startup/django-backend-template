import { test, expect } from "@playwright/test";

test("the real application serves its health endpoint", async ({ page }) => {
  // GIVEN the real ASGI server and an isolated test database

  // WHEN a browser opens the public API endpoint
  await page.goto("/api/health");

  // THEN the application responds successfully
  await expect(page.locator("body")).toHaveText('{"status":"ok"}');
});
