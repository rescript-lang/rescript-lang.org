import { expect, test } from "playwright/test";

test.use({ javaScriptEnabled: false });

const introduction =
  "ReScript is a strongly typed language that compiles to clean,";

test("homepage paragraphs render without JavaScript or downloaded fonts", async ({
  page,
}) => {
  await page.route(/\.(?:woff2?|ttf|otf)(?:\?|$)/, (route) => route.abort());

  await page.goto("/");

  await expect(page.locator("html")).toHaveCSS("opacity", "1");
  await expect(page.getByText(introduction, { exact: false })).toBeVisible();
  await expect(
    page.getByText("Its fast compiler and static type system", {
      exact: false,
    }),
  ).toBeVisible();
  await expect(page.getByText(introduction, { exact: false })).toHaveCSS(
    "color",
    "rgb(105, 107, 125)",
  );
});

for (const path of ["/", "/docs/manual/introduction/"]) {
  test(`${path} remains readable when the shared stylesheet fails`, async ({
    page,
  }) => {
    const stylesheetFailure = page.waitForEvent("requestfailed", {
      predicate: (request) =>
        new URL(request.url()).pathname.startsWith("/assets/main-"),
    });
    await page.route("**/assets/main-*.css", (route) => route.abort());

    await page.goto(path);

    expect((await stylesheetFailure).resourceType()).toBe("stylesheet");
    await expect(page.locator("html")).toHaveCSS("opacity", "1");
    await expect(
      page.getByRole("heading", {
        level: 1,
        name:
          path === "/"
            ? "JavaScript Made Simple for Humans and AI"
            : "ReScript",
        exact: true,
      }),
    ).toBeVisible();
  });
}
