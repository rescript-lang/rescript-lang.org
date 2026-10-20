import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { isAbsolute, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));

export function deadValues(diagnostics, directory = root) {
  if (!Array.isArray(diagnostics)) {
    throw new Error("Expected a JSON array from reanalyze.");
  }

  return diagnostics.filter(({ name, file, message, range }) => {
    if (
      typeof name !== "string" ||
      typeof file !== "string" ||
      typeof message !== "string" ||
      !Array.isArray(range)
    ) {
      throw new Error("Invalid reanalyze diagnostic.");
    }
    const path = relative(directory, file);
    const symbol = message.split(" is never used")[0].split(".").at(-1);
    return (
      (name === "Warning Dead Value" ||
        name === "Warning Dead Value With Side Effects") &&
      !isAbsolute(path) &&
      path !== ".." &&
      !path.startsWith(`..${sep}`) &&
      !path.split(sep).includes("node_modules") &&
      !symbol.startsWith("_")
    );
  });
}

export async function checkDeadCode() {
  for (const artifact of [
    "apps/docs/lib/ocaml/DocsRoot.cmt",
    "apps/guide/lib/ocaml/GuideHome.cmt",
    "packages/playground/lib/ocaml/Playground.cmt",
    "packages/shared/lib/ocaml/RescriptCompilerApi.cmt",
  ]) {
    if (!existsSync(new URL(`../${artifact}`, import.meta.url))) {
      throw new Error("Compile every workspace with yarn build:res first.");
    }
  }

  const { rescript_tools_exe } =
    await import("../node_modules/rescript/cli/common/bins.js");
  const diagnostics = JSON.parse(
    execFileSync(
      rescript_tools_exe,
      ["reanalyze", "-dce", "-externals", "-json"],
      { cwd: root, encoding: "utf8", maxBuffer: 16 * 1024 * 1024 },
    ),
  );
  const unused = deadValues(diagnostics);
  if (unused.length > 0) {
    throw new Error(
      unused
        .map(
          ({ file, range, message }) =>
            `${relative(root, file)}:${range[0] + 1}: ${message}`,
        )
        .join("\n"),
    );
  }
  console.log("No unused ReScript values or exports.");
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  await checkDeadCode();
}
