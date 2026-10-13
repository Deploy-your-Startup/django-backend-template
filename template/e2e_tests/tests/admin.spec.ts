import { test, expect } from "@playwright/test";

test("an anonymous visitor must sign in before opening administration", async ({
  page,
}) => {
  // GIVEN a visitor without a staff session
  // WHEN the visitor opens the real administration page
  await page.goto("/admin/");
  // THEN the application requires credentials before showing any admin data
  await expect(page).toHaveURL(/\/admin\/login\/\?next=/);
  await expect(page.getByLabel("Username:", { exact: true })).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Log in", exact: true }),
  ).toBeVisible();
});
