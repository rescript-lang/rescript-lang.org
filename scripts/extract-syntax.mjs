import glob from "glob";
import path from "path";
import fs from "fs";
import { URL } from "url";

import { defaultProcessor } from "./markdown.js";

const pathname = new URL(".", import.meta.url).pathname;
const __dirname =
  process.platform !== "win32" ? pathname : pathname.substring(1);

const processFile = (filepath) => {
  const content = fs.readFileSync(filepath, "utf8");
  const {
    data: { matter },
  } = defaultProcessor.processSync(content);

  const syntaxPath = path.resolve("./misc_docs/syntax");
  const relFilePath = path.relative(syntaxPath, filepath);
  const parsedPath = path.parse(relFilePath);

  if (
    matter.id &&
    matter.keywords &&
    matter.name &&
    matter.summary &&
    matter.category
  ) {
    return {
      file: parsedPath.name,
      id: matter.id,
      keywords: matter.keywords,
      name: matter.name,
      summary: matter.summary,
      category: matter.category,
    };
  }

  console.error("Metadata missing in " + parsedPath.name + ".mdx");
  return null;
};

const extractSyntax = async (version) => {
  const SYNTAX_MD_DIR = path.join(__dirname, "../misc_docs/syntax");
  const SYNTAX_INDEX_FILE = path.join(
    __dirname,
    "../index_data/syntax_index.json",
  );
  const syntaxFiles = glob.sync(`${SYNTAX_MD_DIR}/*.md?(x)`);
  const syntaxIndex = syntaxFiles
    .map(processFile)
    .filter(Boolean)
    .sort((a, b) => a.name.localeCompare(b.name));
  fs.writeFileSync(SYNTAX_INDEX_FILE, JSON.stringify(syntaxIndex), "utf8");
};

extractSyntax();
