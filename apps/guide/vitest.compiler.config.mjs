import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["__tests__/compiler/*.test.{jsx,js}"],
    testTimeout: 60000,
    expect: { requireAssertions: true },
  },
});
