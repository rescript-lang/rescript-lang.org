import React from "react";
import { renderToReadableStream } from "react-dom/server";
import { isbot } from "isbot";
import { ServerRouter } from "react-router";

export const streamTimeout = 5_000;

export default async function handleRequest(
  request,
  responseStatusCode,
  responseHeaders,
  routerContext,
) {
  if (request.method.toUpperCase() === "HEAD") {
    return new Response(null, {
      status: responseStatusCode,
      headers: responseHeaders,
    });
  }

  let shellRendered = false;
  let userAgent = request.headers.get("user-agent");

  let body = await renderToReadableStream(
    React.createElement(ServerRouter, {
      context: routerContext,
      url: request.url,
    }),
    {
      signal: AbortSignal.timeout(streamTimeout + 1_000),
      onError(error) {
        responseStatusCode = 500;
        if (shellRendered) {
          console.error(error);
        }
      },
    },
  );

  shellRendered = true;

  if (
    ((userAgent && isbot(userAgent)) || routerContext.isSpaMode) &&
    body.allReady
  ) {
    await body.allReady;
  }

  responseHeaders.set("Content-Type", "text/html");

  return new Response(body, {
    headers: responseHeaders,
    status: responseStatusCode,
  });
}
