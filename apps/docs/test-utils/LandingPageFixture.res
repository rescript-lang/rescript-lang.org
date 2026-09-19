let highlightedExample: LandingPage.highlightedExample = {
  res: ShikiHighlighter.highlight(~code=LandingPage.playgroundExample.res, ~language="rescript"),
  js: ShikiHighlighter.highlight(~code=LandingPage.playgroundExample.js, ~language="javascript"),
}
