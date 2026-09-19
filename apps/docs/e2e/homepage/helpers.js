export {
  headline,
  grantClipboardPermissions,
  readClipboard,
} from "./HomepageHelpers.jsx";

export function homepageDocument() {
  return cy.request("/").then(({ status, body }) => {
    expect(status).to.equal(200);
    return new DOMParser().parseFromString(body, "text/html");
  });
}
