import * as fs from "node:fs";
import { routeProfiles } from "./scripts/route-profiles.mjs";

const { stdlibPaths } = await import("./app/DocsRoutes.jsx");
const auditOnlyPaths = routeProfiles
  .filter((profile) => profile.htmlSource === "prerendered")
  .map((profile) => profile.path);

export default {
  ssr: true,
  routeDiscovery: { mode: "initial" },

  prerender: {
    // Restore os.availableParallelism() after https://github.com/remix-run/react-router/issues/15255 is fixed.
    concurrency: 1,
    async paths({ getStaticPaths }) {
      return [
        ...(await getStaticPaths()).filter(
          (path) => path !== "/try" && path !== "try",
        ),
        ...stdlibPaths,
        ...auditOnlyPaths,
      ];
    },
  },
  buildEnd: async () => {
    // Cloudflare serves prerendered pages at trailing-slash URLs. React Router
    // requests /page/_.data for those URLs, while prerendering emits /page.data.
    for (const dataFile of fs.globSync("**/*.data", {
      cwd: "./build/client",
    })) {
      const routeDir = `./build/client/${dataFile.slice(0, -".data".length)}`;
      if (fs.existsSync(`${routeDir}/index.html`)) {
        fs.copyFileSync(`./build/client/${dataFile}`, `${routeDir}/_.data`);
      }
    }

    fs.rmSync("./out", { recursive: true, force: true });
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
