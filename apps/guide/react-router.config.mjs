import * as fs from "node:fs";

export default {
  ssr: false,
  prerender: ["/"],
  buildEnd: async () => {
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};
