import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: [
      "__tests__/GuideLessonFrontmatter_.test.jsx",
      "__tests__/content/*.test.jsx",
    ],
    expect: { requireAssertions: true },
  },
});
