import path from "path";
import child_process from "child_process";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..");

let scriptPath = (name) => path.join(__dirname, name);

export let run = ({
  argv = process.argv.slice(2),
  execFileSync = child_process.execFileSync,
} = {}) => {
  let update = argv.includes("--update");
  let commands = [
    {
      script: scriptPath("test-examples.mjs"),
      args: update ? ["--update"] : [],
    },
    {
      script: scriptPath("test-hrefs.mjs"),
      args: [],
    },
  ];

  for (let command of commands) {
    execFileSync(process.execPath, [command.script, ...command.args], {
      cwd: projectRoot,
      stdio: "inherit",
    });
  }
};

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  run();
}
