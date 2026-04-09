Cypress.on("uncaught:exception", (err) => {
  if (
    err.message.includes("Hydration") ||
    err.message.includes("hydrat") ||
    err.message.includes("Text content does not match") ||
    err.message.includes("did not match") ||
    err.message.includes("Minified React error #418") ||
    err.message.includes("Minified React error #423") ||
    err.message.includes("Minified React error #425")
  ) {
    return false;
  }
});
