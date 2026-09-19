import { expect, test } from "playwright/test";

const boldFont = "/fonts/subset-Inter-Bold.woff2";
const headline = "JavaScript Made Simple for Humans and AI";

for (const width of [375, 1023]) {
  test(`homepage at ${width}px does not request the desktop headline font`, async ({
    page,
  }) => {
    const fontRequests = [];
    page.on("request", (request) => {
      if (request.resourceType() === "font") {
        fontRequests.push(new URL(request.url()).pathname);
      }
    });
    await page.setViewportSize({ width, height: 900 });
    await page.goto("/");

    await expect(
      page.getByRole("heading", { level: 1, name: headline }),
    ).toHaveCSS("font-weight", "600");
    await page.evaluate(async () => {
      await document.fonts.ready;
    });
    expect(fontRequests).toContain("/fonts/subset-Inter-SemiBold.woff2");
    expect(fontRequests).not.toContain(boldFont);
  });
}

test("the desktop headline font loads at the 1024px breakpoint", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1024, height: 900 });
  const fontResponse = page.waitForResponse(
    (response) => new URL(response.url()).pathname === boldFont,
  );
  await page.goto("/");

  await expect(
    page.getByRole("heading", { level: 1, name: headline }),
  ).toHaveCSS("font-weight", "700");
  expect((await fontResponse).ok()).toBe(true);
});
