import * as fs from "node:fs";
import * as os from "node:os";

const { stdlibPaths } = await import("./app/DocsRoutes.jsx");

export default {
  ssr: true,
  routeDiscovery: { mode: "initial" },

  prerender: {
    concurrency: os.availableParallelism(),
    async paths({ getStaticPaths }) {
      return [
        ...(await getStaticPaths()).filter(
          (path) => path !== "/try" && path !== "try",
        ),
        ...stdlibPaths,
      ];
    },
  },
  buildEnd: async () => {
    fs.rmSync("./out", { recursive: true, force: true });
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
