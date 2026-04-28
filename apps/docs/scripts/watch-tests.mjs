import chokidar from "chokidar";
// We switch from 'exec' to 'spawn' and 'execSync' is not needed
import { spawn } from "child_process";

// 1. Define the folder to watch
const folderToWatch = "markdown-pages";

// 2. Define the command and arguments to run
// The command is 'node' and the arguments are the script and its options
const command = "node";
const args = ["scripts/test-hrefs.mjs"];

console.log(`\n👀 Watching for changes in: ${folderToWatch}`);
console.log(`\n➡️  Command to run on change: ${command} ${args.join(" ")}\n`);

// 3. Initialize the watcher
chokidar
  .watch(folderToWatch, {
    ignored: /(^|[\/\\])\../,
    persistent: true,
  })
  .on("change", (path) => {
    console.log(`\n--- 📝 File changed: ${path} ---`);

    // Use spawn instead of exec to run the script
    const child = spawn(command, args, {
      // *** KEY CHANGE: 'inherit' is used to connect the child's stdout/stderr
      // to the parent process's (your watcher script's) stdout/stderr. ***
      stdio: "inherit",
      shell: true, // Use 'shell: true' if the script is simple, or if it needs shell features
    });

    // The 'close' event fires when the process exits
    child.on("close", (code) => {
      if (code !== 0) {
        // Log a custom error message if the script fails
        console.log(`\n❌ Script finished with exit code ${code}`);
      } else {
        // Log a success message
        console.log(`\n✅ Script execution complete.`);
      }
      console.log(`\nWatching again...\n`);
    });

    // Handle process errors (e.g., command not found)
    child.on("error", (err) => {
      console.error(`\n💣 Failed to start child process: ${err}`);
    });
  });
