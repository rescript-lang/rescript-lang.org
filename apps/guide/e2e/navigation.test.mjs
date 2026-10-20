import { expect, test } from "playwright/test";

test("browser Back and Forward restore the guide lesson and saved code", async ({
  page,
}) => {
  const savedCode = 'let greeting = "saved greeting"';
  await page.addInitScript((code) => {
    localStorage.setItem(
      "rescript-guide:v1:progress",
      JSON.stringify({ completedExerciseIds: ["first-contact/greeting"] }),
    );
    localStorage.setItem(
      "rescript-guide:v1:exercise:first-contact/greeting",
      code,
    );
  }, savedCode);

  await page.goto("/#first-contact");
  await expect(
    page.getByRole("heading", { name: "Learn ReScript Guide", exact: true }),
  ).toBeVisible();
  await expect(page.getByTestId("guide-code-editor")).toContainText(savedCode);
  await expect(page.getByTestId("guide-check-status")).toContainText(
    "Checkpoint complete",
  );

  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(page).toHaveURL(/#functions$/);
  await expect(
    page.getByRole("heading", { name: "Call A Function", exact: true }),
  ).toBeVisible();

  await page.goBack();
  await expect(page).toHaveURL(/#first-contact$/);
  await expect(
    page.getByRole("heading", { name: "Learn ReScript Guide", exact: true }),
  ).toBeVisible();
  await expect(page.getByTestId("guide-code-editor")).toContainText(savedCode);

  await page.goForward();
  await expect(page).toHaveURL(/#functions$/);
  await expect(
    page.getByRole("heading", { name: "Call A Function", exact: true }),
  ).toBeVisible();
});
