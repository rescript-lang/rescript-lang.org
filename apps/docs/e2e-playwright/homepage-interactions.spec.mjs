import { expect, test } from "playwright/test";

test("community gallery supports keyboard selection and wraps to the first photo", async ({
  page,
}) => {
  await page.goto("/");

  const firstPhoto = page.getByRole("button", {
    name: "Show community photo 1",
  });
  const thirdPhoto = page.getByRole("button", {
    name: "Show community photo 3",
  });
  const nextPhoto = page.getByRole("button", { name: "Next community photo" });

  await expect(firstPhoto).toHaveAttribute("aria-pressed", "true");
  await thirdPhoto.focus();
  await thirdPhoto.press("Enter");
  await expect(thirdPhoto).toHaveAttribute("aria-pressed", "true");
  await expect(thirdPhoto).toBeFocused();
  await expect(
    page.getByRole("img", { name: "ReScript community photo 3" }),
  ).toBeVisible();

  await nextPhoto.focus();
  await nextPhoto.press("Space");
  await expect(firstPhoto).toHaveAttribute("aria-pressed", "true");
  await expect(nextPhoto).toBeFocused();
  await expect(
    page.getByRole("img", { name: "ReScript community photo 1" }),
  ).toBeVisible();
});

test("clipboard denial can recover and both install commands can be copied repeatedly", async ({
  context,
  page,
}) => {
  const origin = "http://127.0.0.1:4173";
  await context.grantPermissions([], { origin });
  await page.goto("/");

  const firstCopyButton = page.getByRole("button", {
    name: "Copy npm install rescript command",
  });
  await firstCopyButton.click();
  await expect(
    page.getByText("Could not copy. Try again.", { exact: true }),
  ).toBeVisible();
  await expect(firstCopyButton).toBeEnabled();
  await context.grantPermissions(["clipboard-read", "clipboard-write"], {
    origin,
  });

  for (const command of ["npm install rescript", "npx create-rescript-app"]) {
    const copyButton = page.getByRole("button", {
      name: `Copy ${command} command`,
    });

    await copyButton.click();
    await expect(page.getByRole("status")).toContainText(["Copied!"]);
    await expect
      .poll(() => page.evaluate(() => navigator.clipboard.readText()))
      .toBe(command);
    await expect(copyButton).toBeEnabled();
    await expect(page.getByText("Copied!", { exact: true })).toHaveCount(0);
    await copyButton.click();
    await expect(page.getByText("Copied!", { exact: true })).toBeVisible();
    await expect(copyButton).toBeEnabled();
  }
});
