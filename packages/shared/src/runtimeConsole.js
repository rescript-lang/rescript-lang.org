export function serializeArg(arg) {
  if (arg === undefined) return "undefined";
  if (arg === null) return "null";
  if (typeof arg === "object")
    return JSON.stringify(arg, Object.getOwnPropertyNames(arg));
  if (typeof arg === "function") return arg.toString();
  return arg;
}

function installConsole(serializeArg) {
  const sendLog =
    (level) =>
    (...args) => {
      parent.window.postMessage(
        { type: level, args: args.map(serializeArg) },
        "*",
      );
    };
  console.log = sendLog("log");
  console.warn = sendLog("warn");
  console.error = sendLog("error");
}

// Both functions are self-contained so the iframe can install them without module loading.
export const bridgeScript = `(${installConsole.toString()})(${serializeArg.toString()});`;
