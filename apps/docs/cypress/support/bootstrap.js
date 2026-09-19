export function removeCypressBootstrap(window) {
  const bootstrap = window.document.currentScript;
  if (!bootstrap?.textContent.includes("app:window:before:load")) return false;

  // Cypress 15's insertAfter adds exactly one space before its bootstrap.
  // Remove only those test nodes before React hydrates the document.
  const padding = bootstrap.previousSibling;
  if (
    padding?.nodeType === window.Node.TEXT_NODE &&
    padding.textContent === " "
  ) {
    padding.remove();
  }
  bootstrap.remove();
  return true;
}
