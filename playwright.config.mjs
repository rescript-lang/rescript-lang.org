import { defineConfig, devices } from "@playwright/test";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/**
 * The base URL for all page.goto('/') calls in tests.
 *
 * • CI (PR preview): set to the Cloudflare Pages preview URL, e.g.
 *   https://my-feature-branch.rescript-lang.pages.dev
 * • Local: not set — Playwright starts Wrangler automatically and points
 *   tests at http://localhost:8788.
 */
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:8788";

/**
 * Whether we should let Playwright manage the local dev server.
 * We only do this when there is no external URL to point at (i.e. local runs).
 */
const useLocalServer = !process.env.PLAYWRIGHT_BASE_URL;

export default defineConfig({
  /**
   * Start Wrangler Pages dev server automatically for local runs so that
   * `yarn e2e` works after `yarn build` with zero extra setup.
   *
   * The server is NOT started in CI because `PLAYWRIGHT_BASE_URL` is always
   * set there to the Cloudflare preview URL.
   *
   * `reuseExistingServer` lets you keep a Wrangler process running in another
   * terminal and have Playwright attach to it rather than spawning a new one.
   */
  webServer: useLocalServer
    ? {
        command: `yarn wrangler pages dev ${path.join(__dirname, "out")} --port 8788`,
        url: "http://localhost:8788",
        reuseExistingServer: true,
        stdout: "pipe",
        stderr: "pipe",
        timeout: 60_000,
      }
    : undefined,

  testDir: "./e2e",

  /**
   * Include compiled ReScript output (.jsx) as well as plain .js / .ts files.
   * ReScript compiles *.res → *.jsx (in-source), so Playwright must discover
   * those generated files.
   */
  testMatch: "**/*.test.{js,jsx,ts,tsx}",

  /** Run each test file in parallel. */
  fullyParallel: true,

  /**
   * Fail the suite immediately when a test.only() call is left in source —
   * this is enforced only in CI so local debugging is unaffected.
   */
  forbidOnly: !!process.env.CI,

  /** Retry flaky tests twice in CI; never locally so failures are obvious. */
  retries: process.env.CI ? 2 : 0,

  /** Limit parallelism in CI to avoid overwhelming the preview deployment. */
  workers: process.env.CI ? 2 : undefined,

  reporter: process.env.CI
    ? [
        ["github"], // Annotate PR checks with inline failure messages.
        ["html", { open: "never", outputFolder: "playwright-report" }],
        ["json", { outputFile: "test-results/results.json" }],
      ]
    : [["html", { open: "on-failure" }]],

  use: {
    baseURL,

    /**
     * Collect a Playwright trace on the first retry so failures can be
     * inspected in the Playwright trace viewer without slowing down the
     * initial run.
     */
    trace: "on-first-retry",

    /**
     * Capture a screenshot automatically on test failure.
     */
    screenshot: "only-on-failure",

    /**
     * Record a video on the first retry alongside the trace.
     */
    video: "on-first-retry",
  },

  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1440, height: 900 },
      },
    },
    {
      name: "mobile-chrome",
      use: {
        ...devices["Pixel 5"],
      },
    },
  ],

  /** Where Playwright writes screenshots, traces, and videos. */
  outputDir: "test-results",
});
