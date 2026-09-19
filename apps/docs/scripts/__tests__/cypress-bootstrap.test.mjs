import assert from "node:assert/strict";
import { test } from "node:test";
import { JSDOM } from "jsdom";
import { removeCypressBootstrap } from "../../cypress/support/bootstrap.js";

function render(head, context) {
  const results = [];
  const dom = new JSDOM(
    `<!doctype html><html><head>${head}</head><body><h1>Homepage</h1></body></html>`,
    {
      runScripts: "dangerously",
      beforeParse(window) {
        window.bootstrap = () => results.push(removeCypressBootstrap(window));
      },
    },
  );
  context.after(() => dom.window.close());
  return { document: dom.window.document, results };
}

const bootstrap =
  "<script>/* app:window:before:load */ window.bootstrap()</script>";

test("removes only the executing Cypress bootstrap and its single padding space", (context) => {
  const appHead =
    '<style>body { color: red }</style><script type="application/json">{"app":true}</script>';
  const { document, results } = render(` ${bootstrap}${appHead}`, context);
  assert.deepEqual(results, [true]);
  assert.equal(document.head.innerHTML, appHead);
  assert.equal(document.body.innerHTML, "<h1>Homepage</h1>");
});

test("preserves application text, elements, and later scripts", (context) => {
  const prefix = '<meta charset="utf-8">\n  ';
  const suffix = "<script>window.applicationRan = true</script>";
  const { document, results } = render(
    `${prefix}${bootstrap}${suffix}`,
    context,
  );
  assert.deepEqual(results, [true]);
  assert.equal(document.head.innerHTML, `${prefix}${suffix}`);
  assert.equal(document.defaultView.applicationRan, true);
});

test("also handles a bootstrap without padding", (context) => {
  const { document, results } = render(bootstrap, context);
  assert.deepEqual(results, [true]);
  assert.equal(document.head.innerHTML, "");
});

test("does not remove an application script or operate after script execution", (context) => {
  const script = "<script>window.bootstrap()</script>";
  const { document, results } = render(script, context);
  assert.deepEqual(results, [false]);
  assert.equal(document.head.innerHTML, script);
  assert.equal(removeCypressBootstrap(document.defaultView), false);
});
