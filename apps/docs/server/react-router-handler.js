import { createRequestHandler } from "react-router";

const mode = globalThis.process?.env?.NODE_ENV ?? "production";

const handleReactRouterRequest = createRequestHandler(
  () => import("../build/server/index.js"),
  mode,
);

export function onRequest(context) {
  return handleReactRouterRequest(context.request, {
    cloudflare: {
      env: context.env,
    },
  });
}
