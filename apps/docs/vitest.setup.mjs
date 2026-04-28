import "./styles/main.css";
import "./styles/_hljs.css";
import "./styles/utils.css";
import "./styles/test-overrides.css";

import hljs from "highlight.js/lib/core";
import bash from "highlight.js/lib/languages/bash";
import css from "highlight.js/lib/languages/css";
import diff from "highlight.js/lib/languages/diff";
import javascript from "highlight.js/lib/languages/javascript";
import typescript from "highlight.js/lib/languages/typescript";
import json from "highlight.js/lib/languages/json";
import text from "highlight.js/lib/languages/plaintext";
import html from "highlight.js/lib/languages/xml";
import toml from "highlight.js/lib/languages/ini";
import rescript from "highlightjs-rescript";

hljs.registerLanguage("rescript", rescript);
hljs.registerLanguage("javascript", javascript);
hljs.registerLanguage("css", css);
hljs.registerLanguage("ts", typescript);
hljs.registerLanguage("sh", bash);
hljs.registerLanguage("bash", bash);
hljs.registerLanguage("toml", toml);
hljs.registerLanguage("json", json);
hljs.registerLanguage("text", text);
hljs.registerLanguage("html", html);
hljs.registerLanguage("diff", diff);
hljs.registerLanguage("typescript", typescript);
