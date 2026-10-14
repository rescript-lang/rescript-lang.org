import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["__tests__/compiler/*_.test.jsx"],
    testTimeout: 60000,
    expect: { requireAssertions: true },
  },
});
