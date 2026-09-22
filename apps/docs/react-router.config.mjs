import * as fs from "node:fs";
import { routeProfiles } from "./scripts/route-profiles.mjs";

const { stdlibPaths } = await import("./app/DocsRoutes.jsx");
const auditOnlyPaths = routeProfiles.map((profile) => profile.path);

export default {
  ssr: true,
  routeDiscovery: { mode: "initial" },

  prerender: {
    // Restore os.availableParallelism() after https://github.com/remix-run/react-router/issues/15255 is fixed.
    concurrency: 1,
    async paths({ getStaticPaths }) {
      return [...(await getStaticPaths()), ...stdlibPaths, ...auditOnlyPaths];
    },
  },
  buildEnd: async () => {
    fs.rmSync("./out", { recursive: true, force: true });
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
