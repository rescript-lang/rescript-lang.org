import { afterEach, vi } from "vitest";

afterEach(() => {
  vi.restoreAllMocks();
});

// Intercept script insertion rather than loading a remote compiler in UI failure tests.
export function interceptCompilerScripts(fail) {
  const appendChild = document.body.appendChild.bind(document.body);
  vi.spyOn(document.body, "appendChild").mockImplementation((node) => {
    if (
      node instanceof HTMLScriptElement &&
      node.src.includes("/compiler.js")
    ) {
      if (fail) queueMicrotask(() => node.dispatchEvent(new Event("error")));
      return node;
    }
    return appendChild(node);
  });
}

export function expireCompilerLoading() {
  // Advance only the guide's loading deadline; leave editor and test-library timers real.
  const setTimeout = window.setTimeout.bind(window);
  vi.spyOn(window, "setTimeout").mockImplementation(
    (callback, delay, ...args) =>
      setTimeout(callback, delay === 15000 ? 0 : delay, ...args),
  );
}
