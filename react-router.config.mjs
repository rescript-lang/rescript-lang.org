import * as fs from "node:fs";

const { stdlibPaths } = await import("./app/routes.jsx");

export default {
  ssr: false,

  async prerender({ getStaticPaths }) {
    return [...(await getStaticPaths()), ...stdlibPaths];
  },
  buildEnd: async () => {
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
