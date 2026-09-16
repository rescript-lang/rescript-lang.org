import * as fs from "node:fs";

const { stdlibPaths } = await import("./app/DocsRoutes.jsx");

export default {
  ssr: false,

  prerender: {
    // Restore os.availableParallelism() after https://github.com/remix-run/react-router/issues/15255 is fixed.
    concurrency: 1,
    async paths({ getStaticPaths }) {
      return [...(await getStaticPaths()), ...stdlibPaths];
    },
  },
  buildEnd: async () => {
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
