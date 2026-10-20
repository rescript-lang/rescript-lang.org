import { afterEach, vi } from "vitest";

afterEach(() => {
  vi.restoreAllMocks();
});

export function expireCompilerLoading() {
  // Advance only the guide's loading deadline; leave editor and test-library timers real.
  const setTimeout = window.setTimeout.bind(window);
  vi.spyOn(window, "setTimeout").mockImplementation(
    (callback, delay, ...args) =>
      setTimeout(callback, delay === 15000 ? 0 : delay, ...args),
  );
}
