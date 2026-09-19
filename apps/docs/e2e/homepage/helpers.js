export const headline = "JavaScript Made Simple for Humans and AI";

export function grantClipboardPermissions() {
  return cy.then(() =>
    Cypress.automation("remote:debugger:protocol", {
      command: "Browser.grantPermissions",
      params: {
        permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"],
        origin: new URL(Cypress.config("baseUrl")).origin,
      },
    }),
  );
}

export function readClipboard() {
  return cy.window().then((window) => window.navigator.clipboard.readText());
}

export function homepageDocument() {
  return cy.request("/").then(({ status, body }) => {
    expect(status).to.equal(200);
    return new DOMParser().parseFromString(body, "text/html");
  });
}
