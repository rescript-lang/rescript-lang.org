import * as fs from "node:fs";
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";
import { createRequestHandler } from "react-router";

const { stdlibPaths } = await import("./app/DocsRoutes.jsx");

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
      ];
    },
  },
  buildEnd: async () => {
    // A top-level 404.html disables Cloudflare Pages' homepage fallback. Render
    // the wildcard route from the server build to keep the app's normal shell.
    const serverBuild = await import(
      pathToFileURL(resolve("build/server/index.js"))
    );
    const handler = createRequestHandler(serverBuild, "production");
    const response = await handler(
      new Request("https://rescript-lang.org/404"),
    );
    if (response.status !== 404) {
      throw new Error(
        `Expected the wildcard route to return 404, got ${response.status}`,
      );
    }
    fs.writeFileSync("./build/client/404.html", await response.text());

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
