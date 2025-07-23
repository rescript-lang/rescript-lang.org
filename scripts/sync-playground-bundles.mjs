import * as path from "node:path";
import * as fs from "node:fs";
import * as childProcess from "node:child_process";
import { Readable } from "node:stream";
import * as stream from "node:stream/promises";

const bucketUrl = new URL("https://cdn.rescript-lang.org");

const bundlesDir = path.join(import.meta.dirname, "../public/playground-bundles");
fs.mkdirSync(bundlesDir, { recursive: true });

const versions = await fetch(new URL("/playground-bundles/versions.json", bucketUrl))
  .then(res => res.json());

for (const version of versions) {
  const versionDir = path.join(bundlesDir, version);
  const compilerFile = path.join(versionDir, "compiler.js");
  if (fs.existsSync(compilerFile)) {
    console.log(`%s has already been synced.`, version);
    continue;
  }

  console.group(`Syncing %s...`, version);
  {
    console.log(`Downloading archive file...`);
    const res = await fetch(new URL(`/playground-bundles/${version}.tar.zst`, bucketUrl));
    if (!res.ok) {
      console.error(await res.text());
      continue;
    }

    const archiveFile = path.join(bundlesDir, `${version}.tar.zst`);
    const fileStream = fs.createWriteStream(archiveFile);
    await stream.finished(Readable.fromWeb(res.body).pipe(fileStream));

    console.log("Extracting archive...");
    fs.mkdirSync(versionDir, { recursive: true });
    childProcess.execSync(`tar --zstd -xf "${archiveFile}" -C "${versionDir}"`);

    console.log("Cleaning up...");
    fs.unlinkSync(archiveFile);

    console.groupEnd();
  }
}
