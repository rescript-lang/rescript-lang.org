import unified from "unified";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import remarkRehype from "remark-rehype";
import rehypeSlug from "rehype-slug";

const remarkHeaders = options => (tree, file) => {
  const headers = [];
  let mainHeader;
  tree.children.forEach(child => {
    if (child.type === "heading" && child.depth === 1) {
      if (child.children.length > 0) {
        mainHeader = child.children.map(element => element.value).join("");
      }
    }
    if (child.type === "heading" && child.depth === 2) {
      if (child.children.length > 0) {
        const id = child.data.id || "";
        const name = child.children.map(element => element.value).join("");
        headers.push({ name, href: id });
      }
    }
  });

  file.data = Object.assign({}, file.data, { headers, mainHeader });
};

const remarkCodeblocks = options => (tree, file) => {
  const { children } = tree;
  const codeblocks = {};

  const formatter = value => {
    // Strip newlines and weird spacing
    return value
      .replace(/\n/g, " ")
      .replace(/\s+/g, " ")
      .replace(/\(\s+/g, "(")
      .replace(/\s+\)/g, ")");
  };

  children.forEach(child => {
    if (child.type === "code" && child.value) {
      const { meta, lang } = child;
      if (meta === "sig" && lang === "re") {
        if (codeblocks[lang] == null) {
          codeblocks[lang] = [];
        }
        codeblocks[lang].push(formatter(child.value));
      }
    }
  });

  file.data = Object.assign({}, file.data, { codeblocks });
};

export const defaultProcessor = unified()
  .use(remarkGfm)
  .use(remarkFrontmatter, [{ type: 'yaml', marker: '-' }])
  .use(remarkHeaders)
  .use(remarkCodeblocks)
  .use(remarkRehype)
  .use(rehypeSlug)
