import { defineConfig } from "vitest/config";

export default defineConfig({
  envDir: "../..",
  test: {
    environment: "node",
    include: ["scripts/__tests__/*.test.jsx"],
    expect: { requireAssertions: true },
  },
});
