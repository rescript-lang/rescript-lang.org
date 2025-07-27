import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import mdx from "@mdx-js/rollup";
import remarkFrontmatter from "remark-frontmatter";

export default defineConfig({
    plugins: [tailwindcss(), mdx({
        remarkPlugins: [remarkFrontmatter]
    }), reactRouter()],
});