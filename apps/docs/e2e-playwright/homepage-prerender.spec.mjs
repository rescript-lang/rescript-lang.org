import { expect, test } from "playwright/test";
import { JSDOM } from "jsdom";

test("homepage response contains prerendered content and highlighted examples", async ({
  request,
}) => {
  const response = await request.get("/");
  const html = await response.text();
  const { document } = new JSDOM(html).window;

  expect(response.ok()).toBe(true);
  expect(html).toContain("JavaScript Made Simple for Humans and AI");
  expect(html).toContain("Write in ReScript");
  expect(document.querySelector("code.lang-res span")).not.toBeNull();
  expect(document.querySelector("code.lang-js span")).not.toBeNull();
  expect(html).toContain('href="/docs/manual/installation"');
  expect(html).toMatch(/href="\/try\?code=[^"]+"/);

  const fontPreloads = Array.from(
    document.querySelectorAll('head link[rel="preload"][as="font"]'),
    (link) => ({
      href: link.getAttribute("href"),
      type: link.getAttribute("type"),
      crossOrigin: link.getAttribute("crossorigin"),
    }),
  );

  expect(fontPreloads).toEqual([
    {
      href: "/fonts/subset-Inter-Regular.woff2",
      type: "font/woff2",
      crossOrigin: "anonymous",
    },
    {
      href: "/fonts/subset-Inter-SemiBold.woff2",
      type: "font/woff2",
      crossOrigin: "anonymous",
    },
    {
      href: "/fonts/red-hat-mono-700.woff2",
      type: "font/woff2",
      crossOrigin: "anonymous",
    },
  ]);
  expect(html).not.toContain("fonts.googleapis.com");
  expect(html).not.toContain("fonts.gstatic.com");
});
