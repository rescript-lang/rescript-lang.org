import { headline, homepageDocument } from "./helpers.js";

it("homepage response contains prerendered content and highlighted examples", () => {
  homepageDocument().then((document) => {
    expect(document.body.textContent).to.include(headline);
    expect(document.body.textContent).to.include("Write in ReScript");
    expect(document.querySelector("code.lang-res span")).not.to.equal(null);
    expect(document.querySelector("code.lang-js span")).not.to.equal(null);
    expect(
      document.querySelector('a[href="/docs/manual/installation"]'),
    ).not.to.equal(null);
    expect(
      document.querySelector('a[href^="/try?code="]').getAttribute("href"),
    ).to.match(/\/try\?code=.+/);
  });
});
