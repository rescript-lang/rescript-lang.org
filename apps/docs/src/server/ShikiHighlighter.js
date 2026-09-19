import { createHighlighterCoreSync, hastToHtml } from "shiki/core";
import { createJavaScriptRegexEngine } from "shiki/engine/javascript";
import javascript from "@shikijs/langs/javascript";
import githubDark from "@shikijs/themes/github-dark";

// Vendored from rescript-vscode at commit 76d30468cb05401c10dd1e9dcf5a2993f8fc7140.
// https://github.com/rescript-lang/rescript-vscode/blob/76d30468cb05401c10dd1e9dcf5a2993f8fc7140/grammars/rescript.tmLanguage.json
import rescriptGrammar from "./rescript.tmLanguage.json" with { type: "json" };

const highlighter = createHighlighterCoreSync({
  engine: createJavaScriptRegexEngine(),
  langs: [
    javascript,
    {
      ...rescriptGrammar,
      name: "rescript",
      aliases: ["res"],
    },
  ],
  themes: [githubDark],
});

export const highlight = (code, language) => {
  const tree = highlighter.codeToHast(code, {
    lang: language,
    theme: "github-dark",
  });
  const pre = tree.children[0];
  const codeElement = pre.children[0];

  return codeElement.children.map((child) => hastToHtml(child)).join("");
};
