const knownHydrationErrors = [
  /Hydration failed because the initial UI does not match what was rendered on the server\.?/,
  /Text content does not match server-rendered HTML\.?/,
  /There was an error while hydrating\.?/,
  /Minified React error #418\b/,
  /Minified React error #423\b/,
  /Minified React error #425\b/,
];

const knownPlaygroundBootstrapErrors = [
  /Sys_error.*file already exists/i,
  /\/static\/Belt\.cmi\s*:\s*file already exists/i,
];

Cypress.on("uncaught:exception", (err) => {
  const message = err && err.message ? err.message : "";
  const isKnownHydrationError = knownHydrationErrors.some((pattern) =>
    pattern.test(message),
  );
  const isKnownPlaygroundBootstrapError = knownPlaygroundBootstrapErrors.some(
    (pattern) => pattern.test(message),
  );

  if (isKnownHydrationError) {
    console.warn("Suppressing known React hydration exception in Cypress:", {
      message,
      error: err,
    });
    return false;
  }

  if (isKnownPlaygroundBootstrapError) {
    console.warn(
      "Suppressing known Playground bootstrap exception in Cypress:",
      {
        message,
        error: err,
      },
    );
    return false;
  }
});
