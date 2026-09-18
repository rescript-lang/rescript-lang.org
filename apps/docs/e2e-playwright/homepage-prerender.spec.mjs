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
});
