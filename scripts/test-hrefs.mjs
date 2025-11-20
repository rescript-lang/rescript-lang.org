import remarkValidateLinks from "remark-validate-links";
import { remark } from "remark";
import { read } from "to-vfile";
import { reporter } from "vfile-reporter";
import * as fs from "fs/promises";

const files = new Set(
  ...[await fs.readdir("markdown-pages", { recursive: true })],
);

const markdownFolders = (
  await fs.readdir("markdown-pages", { recursive: true, withFileTypes: true })
)
  .filter((dirent) => dirent.isDirectory())
  .map((dirent) => dirent.name);

let issues = 0;

for (const file of files) {
  if (file.includes(".mdx")) {
    let result = await remark()
      .use(remarkValidateLinks)
      .process(await read("markdown-pages/" + file));

    const log = reporter(result, { quiet: true });

    const warningMessage = log.replace(file, "");

    if (
      log &&
      !warningMessage.includes("api/") &&
      // When running on CI it fails to ignore the link directly to the blog root
      // https://github.com/rescript-lang/rescript-lang.org/actions/runs/19520461368/job/55882556586?pr=1115#step:6:338
      !warningMessage.includes("`../../blog`") &&
      markdownFolders.some((folder) => warningMessage.includes(`${folder}`)) &&
      !warningMessage.includes(".txt")
    ) {
      console.log(log);
      issues += 1;
    }
  }
}

console.log(
  `\n${issues > 0 ? "❌" : "✅"} Link check complete. ${issues} issues found.\n`,
);

if (process.env.CI && issues > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
