import * as fs from "node:fs";

const { stdlibPaths } = await import("./app/DocsRoutes.jsx");

export default {
  ssr: false,

  prerender: {
    concurrency: 4,
    async paths({ getStaticPaths }) {
      return [...(await getStaticPaths()), ...stdlibPaths];
    },
  },
  buildEnd: async () => {
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
