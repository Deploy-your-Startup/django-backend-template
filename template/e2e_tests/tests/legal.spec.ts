import { test, expect } from "@playwright/test";

test("anonymous visitors can read legal information before login", async ({
  page,
}) => {
  // GIVEN the real admin login without a session
  await page.goto("/admin/login/");
  // WHEN the visitor follows the legal footer
  await page.getByRole("link", { name: "Impressum", exact: true }).click();
  // THEN the incomplete configuration is identified and privacy stays accessible
  await expect(
    page.getByRole("heading", { name: "Impressum", exact: true }),
  ).toBeVisible();

  await page.getByRole("link", { name: "Privacy policy", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Privacy policy", exact: true }),
  ).toBeVisible();
});
