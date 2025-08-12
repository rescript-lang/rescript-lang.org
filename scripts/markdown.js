import { unified } from "unified"
import remarkParse from "remark-parse"
import remarkGfm from "remark-gfm"
import remarkFrontmatter from "remark-frontmatter"
import remarkRehype from "remark-rehype"
import rehypeSlug from "rehype-slug"
import rehypeStringify from "rehype-stringify"
import { matter } from "vfile-matter"

const remarkVfileMatter = (options) => (tree, file) => {
  matter(file)
}

const remarkCodeblocks = (options) => (tree, file) => {
  const { children } = tree
  const codeblocks = {}

  const formatter = (value) => {
    // Strip newlines and weird spacing
    return value
      .replace(/\n/g, " ")
      .replace(/\s+/g, " ")
      .replace(/\(\s+/g, "(")
      .replace(/\s+\)/g, ")")
  }

  children.forEach((child) => {
    if (child.type === "code" && child.value) {
      const { meta, lang } = child
      if (meta === "sig" && lang === "re") {
        if (codeblocks[lang] == null) {
          codeblocks[lang] = []
        }
        codeblocks[lang].push(formatter(child.value))
      }
    }
  })

  Object.assign(file.data, { codeblocks })
}

const rehypeHeaders = (options) => (tree, file) => {
  const headers = []
  let mainHeader
  tree.children.forEach((child) => {
    if (child.tagName === "h1") {
      if (child.children.length > 0) {
        mainHeader = child.children.map((element) => element.value).join("")
      }
    }
    if (child.tagName === "h2") {
      if (child.children.length > 0) {
        const id = child.properties.id || ""
        const name = child.children.map((element) => element.value).join("")
        headers.push({ name, href: id })
      }
    }
  })

  Object.assign(file.data, { headers, mainHeader })
}

export const defaultProcessor = unified()
  .use(remarkParse)
  .use(remarkGfm)
  .use(remarkFrontmatter, [{ type: "yaml", marker: "-" }])
  .use(remarkVfileMatter)
  .use(remarkCodeblocks)
  .use(remarkRehype)
  .use(rehypeSlug)
  .use(rehypeHeaders)
  .use(rehypeStringify)
