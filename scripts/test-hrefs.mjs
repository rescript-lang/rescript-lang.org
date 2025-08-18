/*
 * This script globs all `pages/*.mdx` files and
 * parses all <a> hrefs with relative links (starting with '/' or `./`)
 *
 * It will report any href which does not link to a valid page within
 * the website.
 */

import { config } from "dotenv";
import fs from "fs";
import glob from "glob";
import path from "path";
import urlModule, { URL } from "url";
import { blogPathToSlug, getAllPosts } from "../src/common/BlogApi.mjs";

import { defaultProcessor } from "./markdown.js";

config();

let latestVersion = process.env.VERSION_LATEST;
let nextVersion = process.env.VERSION_NEXT;

const pathname = new URL(".", import.meta.url).pathname;
const __dirname =
  process.platform !== "win32" ? pathname : pathname.substring(1);

const mapBlogFilePath = (path) => {
  const match = path.match(/\.\/_blogposts\/(.*\.mdx)/);

  if (match) {
    let relPath = match[1];
    let data = getAllPosts().find(({ path }) => path === relPath);
    if (data != null) {
      return `./pages/blog/${blogPathToSlug(data.path)}`;
    }
    return path;
  }
  return path;
};

// Static files are located in /public/img/somefile.png
// within markdown files they are referenced as /img/somefile.png
const mapStaticFilePath = (path) => {
  return path.replace("./public", "");
};

// Creates a lookup table of all available pages within the website
// It will also automatically map urls for dedicated directorys (such as _blogposts)
// to the correct url
// { key=url: value=original_filepath}
const createPageIndex = (files) => {
  return files.reduce((acc, path) => {
    // We need to consider all the different file formats used in pages
    // Calculate the website url by stripping .re, .bs.js, .md(x), etc.
    let url;
    if (path.startsWith("./_blogposts")) {
      url = mapBlogFilePath(path);
    } else if (path.startsWith("./public/static")) {
      url = mapStaticFilePath(path);
    } else {
      url = path;
    }

    url = url.replace(/^\.\//, "/").replace(/\.re|\.bs\.js|\.js|\.md(x)?$/, "");

    // For index we need to special case, since it can be referred as '/' as well
    if (path.match(/\.\/pages\/index(\.re|\.bs\.js|\.js|\.md(x))?$/)) {
      url = "/pages/";
    }

    acc[url] = path;
    return acc;
  }, {});
};

const flattenChildren = (children) => {
  return children.reduce((acc, node) => {
    if (node.type === "link") {
      return acc.concat([node]);
    } else if (node.children) {
      let value = flattenChildren(node.children);
      return acc.concat(value);
    }
    return acc;
  }, []);
};

// Finds all relative links within a file
const hrefs = (options) => (tree, file) => {
  const links = flattenChildren(tree.children);

  file.data = Object.assign({}, file.data, { links });
};

const processor = defaultProcessor.use(hrefs);

const processFile = (filepath) => {
  const content = fs.readFileSync(filepath, "utf8");
  const result = processor.processSync(content);

  result.data.filepath = filepath;

  return result.data;
};

const showErrorMsg = (failedTest) => {
  const { stderr } = failedTest;
  console.log(`\n-----------\nError Preview:`);
  console.log(stderr);
};

const createApiIndexModules = (version) => {
  const dir = path.join(__dirname, "..", "data", "api", version);
  const modules = fs
    .readdirSync(dir)
    .filter((file) => file !== "toc_tree.json");
  const paths = modules.reduce((acc, file) => {
    const json = JSON.parse(fs.readFileSync(path.join(dir, file)));
    const keys = Object.keys(json);

    const paths = keys.map((modulePath) =>
      path.join(version, "api", modulePath),
    );

    return acc.concat(paths);
  }, []);
  return [`${version}/api`, ...paths];
};

const apiIndexModules = [
  ...createApiIndexModules(latestVersion),
  ...createApiIndexModules(nextVersion),
];

const testFile = (pageMap, test) => {
  const filepath = test.filepath;

  // Used for storing failed / ok hrefs
  const results = [];

  test.links.forEach((link) => {
    // Simulate the redirect of "latest" and "next" version aliases.
    if (link.url.includes("/manual/latest/")) {
      link.url = link.url.replace("/latest/", `/${latestVersion}/`);
    }

    if (link.url.includes("/manual/next/")) {
      link.url = link.url.replace("/next/", `/${nextVersion}/`);
    }

    const parsed = urlModule.parse(link.url);

    // Drops .md / .mdx / .html file extension in pathname section, since UI ignores them
    // Needs to be kept in sync with `components/Markdown.re`s <A> component
    // This requirements stems from the original documentation on reasonml.github.io, where lots of .md / .html
    // hrefs are included
    let url = link.url;
    if (parsed.pathname) {
      parsed.pathname = parsed.pathname.replace(/\.md(x)?|\.html$/, "");
      url = urlModule.format(parsed);
    }

    // Scenarios where links should NOT be checked
    // Case 1: url = #hello-world
    // Case 2: url = https://...
    // Case 3: url = //reasonml.github.io/abc/def -> Special markdown link format pointing to external urls
    //
    // Everything else is a relative link and should be checked
    // in the files map
    // Possibe relative links:
    // - /apis/javascript/foo
    // - latest/belt
    // - ../manual/variants
    if (
      parsed.protocol == null &&
      url !== parsed.hash &&
      !parsed.pathname.startsWith("//")
    ) {
      // If there is a relative link like '../manual/latest', we need to resolve it
      // relatively from the links source filepath
      let resolved;
      if (!path.isAbsolute(url)) {
        resolved = path.join("/", path.dirname(filepath), parsed.pathname);
      } else {
        if (parsed.pathname.startsWith("/static")) {
          console.log("Static");
          resolved = path.join(parsed.pathname);
        } else {
          // e.g. /api/javascript/latest/js needs to be prefixed to actual pages dir
          resolved = path.join("/pages", parsed.pathname);
        }
      }

      if (
        resolved.startsWith(`/pages/docs/manual/${latestVersion}/api`) ||
        resolved.startsWith(`/pages/docs/manual/${nextVersion}/api`)
      ) {
        const pathToModule = resolved.replace("/pages/docs/manual/", "");
        const pathExists = apiIndexModules.includes(pathToModule);

        if (pathExists) {
          results.push({
            status: "ok",
            link,
          });
        } else {
          const { line, column } = link.position.start;
          const stderr = `${filepath}: Unknown href '${url}' in line ${line}:${column}`;
          results.push({
            status: "failed",
            filepath,
            stderr,
            link,
          });
        }
        return;
      }

      // If there's no page stated the relative link
      if (!pageMap[resolved]) {
        const { line, column } = link.position.start;
        const stderr = `${filepath}: Unknown href '${url}' in line ${line}:${column}`;
        results.push({
          status: "failed",
          filepath,
          stderr,
          link,
        });
        return;
      }
    }

    results.push({
      status: "ok",
      link,
    });
  });

  if (results.length > 0) {
    console.log(`\n-------Results for '${filepath}'----------`);

    results.forEach((r) => {
      const { status } = r;
      const { line, column } = r.link.position.start;

      if (status === "failed") {
        console.log(
          `${filepath}:${line} => ${status} / Unknown href '${r.link.url}' in line ${line}:${column}`,
        );
      } else {
        console.log(`${filepath}:${line} => ${status}`);
      }
    });
  }

  return {
    data: test,
    results,
  };
};

const main = () => {
  const [, , pattern] = process.argv;
  const cwd = path.join(__dirname, "..");

  // All files that are going to be tested for broken links
  const files = glob.sync(
    pattern ? pattern : `./{pages,_blogposts,misc_docs}/**/*.md?(x)`,
    { cwd },
  );

  // We need to capture all files independently from the test file glob
  const pageMapFiles = glob.sync("./{pages,_blogposts}/**/*.{js,mdx}", { cwd });
  const staticFiles = glob.sync("./public/**/*.{svg,png,woff2}", { cwd });

  const allFiles = pageMapFiles.concat(staticFiles);

  const pageMap = createPageIndex(allFiles);

  const processedFiles = files.map(processFile);

  const allTested = processedFiles.map((file) => testFile(pageMap, file));

  const failed = allTested.reduce((acc, test) => {
    return acc.concat(test.results.filter((r) => r.status === "failed"));
  }, []);

  const success = allTested.reduce((acc, test) => {
    return acc.concat(test.results.filter((r) => r.status === "ok"));
  }, []);

  console.log("-----------\nSummary:");
  console.log(`Total Links: ${failed.length + success.length}`);
  console.log(`Failed: ${failed.length}`);
  console.log(`Success: ${success.length}`);

  if (failed.length > 0) {
    console.log(
      `\nTip: You can also run tests just for specific files / globs:`,
    );
    console.log('`node scripts/test-hrefs.js "pages/**/*.mdx"`');
    showErrorMsg(failed[0]);
    process.exit(1);
  }
};

main();
