import { homepageDocument } from "./helpers.js";

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

function expectAvailableImage(url, format) {
  return cy.request({ url, encoding: "binary" }).then((response) => {
    expect(response.status, url).to.equal(200);
    expect(response.headers["content-type"], url).to.include(`image/${format}`);
    expect(response.body.length, url).to.be.greaterThan(0);
  });
}

function expectAvailableCandidates(element, format, preloadedImages) {
  const entries = candidates(element?.getAttribute("srcset") ?? "");
  expect(entries.map((entry) => entry.width)).to.deep.equal([360, 640, 1000]);
  for (const entry of entries) {
    expect(preloadedImages).not.to.include(entry.url);
    expectAvailableImage(entry.url, format);
  }
}

function expectResponsivePicture(picture, preloadedImages) {
  const sources = [...picture.querySelectorAll("source")];
  expect(sources).to.have.length(1);
  const source = sources.at(0);
  const image = picture.querySelector("img");
  expect(source?.getAttribute("type")).to.equal("image/avif");
  expect(image?.getAttribute("loading")).to.equal("lazy");
  expect(image?.getAttribute("decoding")).to.equal("async");
  expect(image?.getAttribute("sizes")).to.be.a("string").and.not.equal("");
  expect(image?.getAttribute("sizes")).to.equal(source?.getAttribute("sizes"));
  expectAvailableCandidates(source, "avif", preloadedImages);
  expectAvailableCandidates(image, "webp", preloadedImages);
  expectAvailableImage(image?.getAttribute("src") ?? "", "webp");
}

function mediaBounds(window) {
  return [...window.document.querySelectorAll("main img, main video")].map(
    (element) => {
      const bounds = element.getBoundingClientRect();
      const hasBox = bounds.width !== 0 || bounds.height !== 0;
      return {
        width: bounds.width,
        height: bounds.height,
        top: hasBox ? bounds.top + window.scrollY : 0,
      };
    },
  );
}

function captureReservedLayout(window) {
  const { document } = window;
  document.body.getBoundingClientRect();
  // FontFaceSet.ready waits for load, which the held images would block.
  const loadingFonts = [...document.fonts]
    .filter((face) => face.status === "loading")
    .map((face) => face.loaded);
  return Promise.all(loadingFonts).then(
    () =>
      new Promise((resolve) => {
        window.requestAnimationFrame(() => resolve(mediaBounds(window)));
      }),
  );
}

function visitBeforeImageResponses() {
  const snapshot = Promise.withResolvers();
  const release = snapshot.promise.then(
    () => undefined,
    () => undefined,
  );
  cy.on("fail", (error) => {
    snapshot.reject(error);
    throw error;
  });
  cy.intercept({ resourceType: "image" }, () => release);
  cy.visit("/", {
    onBeforeLoad(window) {
      // Release images here so cy.visit can receive its required load event.
      window.document.addEventListener(
        "DOMContentLoaded",
        () => {
          captureReservedLayout(window).then(snapshot.resolve, snapshot.reject);
        },
        { once: true },
      );
    },
  });
  return cy.then(() => snapshot.promise);
}

function decodeHomepageImages() {
  cy.get("main section").each((section) => cy.wrap(section).scrollIntoView());
  cy.get("img").each((image) =>
    cy
      .wrap(image)
      .scrollIntoView()
      .should((images) => {
        expect(images[0].complete, images[0].alt).to.equal(true);
        expect(images[0].naturalWidth, images[0].alt).to.be.greaterThan(0);
      })
      .then((images) => images[0].decode()),
  );
  return cy.window().then((window) => window.document.fonts.ready);
}

function expectSelectedCandidate(name, expectedWidth) {
  return cy
    .get(`img[alt="${name}"]`)
    .scrollIntoView()
    .then(async (images) => {
      const image = images[0];
      await image.decode();
      const source = image.parentElement.querySelector("source");
      const selected = candidates(source.srcset).find(
        (entry) => new URL(entry.url, image.baseURI).href === image.currentSrc,
      );
      expect(selected, `${name} selected AVIF candidate`).not.to.equal(
        undefined,
      );
      expect(selected.width).to.equal(expectedWidth);
      expect(selected.width).to.be.at.least(
        image.getBoundingClientRect().width,
      );
    });
}

it("prerendered homepage reserves dimensions for every image and video", () => {
  homepageDocument().then((document) => {
    const images = [...document.querySelectorAll("img")];
    const videos = [...document.querySelectorAll("video")];
    expect(images).to.have.length(63);
    expect(videos).to.have.length(3);
    for (const element of [...images, ...videos]) {
      const source =
        element.getAttribute("src") ?? element.getAttribute("poster");
      expect(Number(element.getAttribute("width")), source).to.be.greaterThan(
        0,
      );
      expect(Number(element.getAttribute("height")), source).to.be.greaterThan(
        0,
      );
    }
    for (const video of videos) {
      expect(video.getAttribute("preload")).to.equal("none");
    }
  });
});

it("prerendered responsive media exposes valid AVIF and WebP candidates", () => {
  homepageDocument().then((document) => {
    const pictures = [...document.querySelectorAll("picture")];
    expect(pictures).to.have.length(3);
    const preloadedImages = imagePreloadUrls(document);
    for (const picture of pictures) {
      expectResponsivePicture(picture, preloadedImages);
    }
  });
});

for (const width of [375, 1440]) {
  it(`responsive images select appropriately sized files at ${width}px`, () => {
    cy.viewport(width, 900);
    cy.visit("/");
    for (const name of responsiveNames) {
      const expectedWidth =
        width === 375 && name !== "ReScript community photo 1" ? 360 : 640;
      expectSelectedCandidate(name, expectedWidth);
    }
    for (const index of [2, 3]) {
      cy.get(`button[aria-label="Show community photo ${index}"]`).click();
      expectSelectedCandidate(`ReScript community photo ${index}`, 640);
      cy.get(`img[alt="ReScript community photo ${index}"]`)
        .should("be.visible")
        .and("have.attr", "width", index === 2 ? "1355" : "1000")
        .and("have.attr", "height", index === 2 ? "904" : "667");
    }
  });

  it(`homepage media reserves its loaded layout before image responses at ${width}px`, () => {
    cy.viewport(width, 900);
    visitBeforeImageResponses().then((reserved) => {
      decodeHomepageImages();
      cy.window().then((window) => {
        const loaded = mediaBounds(window);
        expect(loaded).to.have.length(reserved.length);
        loaded.forEach((bounds, index) => {
          for (const dimension of ["width", "height", "top"]) {
            expect(
              bounds[dimension],
              `media ${index} ${dimension}`,
            ).to.be.closeTo(reserved[index][dimension], 0.5);
          }
        });
      });
    });
  });
}
