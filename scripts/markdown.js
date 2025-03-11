import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkStringify from "remark-stringify";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import { matter } from "vfile-matter";

export const vfileMatter = options => (tree, file) => {
  matter(file);
};

export const defaultProcessor = unified()
  .use(remarkParse)
  .use(remarkStringify)
  .use(remarkGfm)
  .use(remarkFrontmatter, [{ type: 'yaml', marker: '-' }])
  .use(vfileMatter);
