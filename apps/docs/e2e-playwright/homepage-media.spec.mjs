import { expect, test } from "playwright/test";
import { JSDOM } from "jsdom";

const responsiveNames = [
  "ReScript community photo 1",
  "ReScript editor tooling",
  "ReScript JavaScript output",
];

function candidates(sourceSet) {
  return sourceSet.split(",").map((candidate) => {
    const [url, width] = candidate.trim().split(/\s+/);
    return { url, width: Number.parseInt(width, 10) };
  });
}

function imagePreloadUrls(document) {
  return [
    ...document.querySelectorAll('link[rel="preload"][as="image"]'),
  ].flatMap((link) => {
    const sourceSet = link.getAttribute("imagesrcset");
    return [
      link.getAttribute("href"),
      ...(sourceSet === null
        ? []
        : candidates(sourceSet).map((entry) => entry.url)),
    ];
  });
}

async function expectAvailableCandidates(
  request,
  { element, format, preloadedImages },
) {
  const entries = candidates(element?.getAttribute("srcset") ?? "");
  expect(entries.map((entry) => entry.width)).toEqual([360, 640, 1000]);
  for (const entry of entries) {
    expect(preloadedImages).not.toContain(entry.url);
    const asset = await request.get(entry.url);
    expect(asset.ok(), entry.url).toBe(true);
    expect(asset.headers()["content-type"], entry.url).toContain(
      `image/${format}`,
    );
    expect((await asset.body()).byteLength, entry.url).toBeGreaterThan(0);
  }
}

async function decodeHomepageImages(page) {
  for (const section of await page.locator("main section").all()) {
    await section.scrollIntoViewIfNeeded();
  }
  await page.locator("img").evaluateAll(async (images) => {
    await Promise.all(images.map((image) => image.decode()));
    await document.fonts.ready;
  });
}

async function mediaBounds(page) {
  await page.evaluate(() => document.fonts.ready);
  return page.locator("main img, main video").evaluateAll((elements) =>
    elements.map((element) => {
      const bounds = element.getBoundingClientRect();
      const hasBox = bounds.width !== 0 || bounds.height !== 0;
      return {
        width: bounds.width,
        height: bounds.height,
        top: hasBox ? bounds.top + window.scrollY : 0,
      };
    }),
  );
}

async function expectSelectedCandidate(image, expectedWidth, pageUrl) {
  await image.scrollIntoViewIfNeeded();
  await image.evaluate((element) => element.decode());
  const selection = await image.evaluate((element) => ({
    currentSrc: element.currentSrc,
    avif: element.parentElement.querySelector("source").srcset,
    renderedWidth: element.getBoundingClientRect().width,
  }));
  const selected = candidates(selection.avif).find(
    (entry) => new URL(entry.url, pageUrl).href === selection.currentSrc,
  );
  expect(selected).toBeDefined();
  expect(selected?.width).toBe(expectedWidth);
  expect(selected?.width).toBeGreaterThanOrEqual(selection.renderedWidth);
}

test("prerendered homepage reserves dimensions for every image and video", async ({
  request,
}) => {
  const response = await request.get("/");
  expect(response.ok()).toBe(true);
  const { document } = new JSDOM(await response.text()).window;
  const images = [...document.querySelectorAll("img")];
  const videos = [...document.querySelectorAll("video")];

  expect(images).toHaveLength(63);
  expect(videos).toHaveLength(3);
  for (const element of [...images, ...videos]) {
    const source =
      element.getAttribute("src") ?? element.getAttribute("poster");
    expect(Number(element.getAttribute("width")), source).toBeGreaterThan(0);
    expect(Number(element.getAttribute("height")), source).toBeGreaterThan(0);
  }
  for (const video of videos) {
    expect(video.getAttribute("preload")).toBe("none");
  }
});

test("prerendered responsive media exposes valid AVIF and WebP candidates", async ({
  request,
}) => {
  const response = await request.get("/");
  expect(response.ok()).toBe(true);
  const { document } = new JSDOM(await response.text()).window;
  const pictures = [...document.querySelectorAll("picture")];
  expect(pictures).toHaveLength(3);
  const preloadedImages = imagePreloadUrls(document);

  for (const picture of pictures) {
    const sources = [...picture.querySelectorAll("source")];
    expect(sources).toHaveLength(1);
    const source = sources.at(0);
    const image = picture.querySelector("img");
    expect(source?.getAttribute("type")).toBe("image/avif");
    expect(image?.getAttribute("loading")).toBe("lazy");
    expect(image?.getAttribute("decoding")).toBe("async");
    expect(image?.getAttribute("sizes")).toEqual(expect.any(String));
    expect(image?.getAttribute("sizes")).toBe(source?.getAttribute("sizes"));
    expect(image?.getAttribute("sizes")).not.toBe("");

    for (const [element, format] of [
      [source, "avif"],
      [image, "webp"],
    ]) {
      await expectAvailableCandidates(request, {
        element,
        format,
        preloadedImages,
      });
    }
    const fallback = await request.get(image?.getAttribute("src") ?? "");
    expect(fallback.ok()).toBe(true);
    expect(fallback.headers()["content-type"]).toContain("image/webp");
  }
});

for (const width of [375, 1440]) {
  test(`responsive images select appropriately sized files at ${width}px`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: 900 });
    await page.goto("/");

    for (const name of responsiveNames) {
      const image = page.getByRole("img", { name, exact: true });
      const expectedWidth =
        width === 375 && name !== "ReScript community photo 1" ? 360 : 640;
      await expectSelectedCandidate(image, expectedWidth, page.url());
    }

    for (const index of [2, 3]) {
      await page
        .getByRole("button", { name: `Show community photo ${index}` })
        .click();
      const image = page.getByRole("img", {
        name: `ReScript community photo ${index}`,
        exact: true,
      });
      await expectSelectedCandidate(image, 640, page.url());
      await expect(image).toBeVisible();
      await expect(image).toHaveAttribute(
        "width",
        index === 2 ? "1355" : "1000",
      );
      await expect(image).toHaveAttribute(
        "height",
        index === 2 ? "904" : "667",
      );
    }
  });

  test(`homepage media reserves its loaded layout before image responses at ${width}px`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: 900 });
    const responses = Promise.withResolvers();
    await page.route("**/*", async (route) => {
      if (route.request().resourceType() === "image") {
        await responses.promise;
      }
      await route.continue();
    });
    try {
      await page.goto("/", { waitUntil: "domcontentloaded" });
      const reserved = await mediaBounds(page);
      responses.resolve();
      await decodeHomepageImages(page);
      const loaded = await mediaBounds(page);

      expect(loaded).toHaveLength(reserved.length);
      loaded.forEach((bounds, index) => {
        expect(bounds.width).toBeCloseTo(reserved[index].width, 0);
        expect(bounds.height).toBeCloseTo(reserved[index].height, 0);
        expect(bounds.top).toBeCloseTo(reserved[index].top, 0);
      });
    } finally {
      responses.resolve();
      await page.unrouteAll({ behavior: "wait" });
    }
  });
}
