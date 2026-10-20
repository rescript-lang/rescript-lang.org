import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["scripts/__tests__/*.test.jsx"],
    expect: { requireAssertions: true },
  },
});
