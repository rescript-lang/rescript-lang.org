import * as fs from "node:fs";
import * as os from "node:os";

const { stdlibPaths } = await import("./app/DocsRoutes.jsx");

export default {
  ssr: false,

  prerender: {
    concurrency: os.availableParallelism(),
    async paths({ getStaticPaths }) {
      return [...(await getStaticPaths()), ...stdlibPaths];
    },
  },
  buildEnd: async () => {
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
