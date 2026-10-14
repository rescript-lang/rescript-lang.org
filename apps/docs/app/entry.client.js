import { createElement, startTransition, StrictMode } from "react";
import { createRoot, hydrateRoot } from "react-dom/client";
import { HydratedRouter } from "react-router/dom";

startTransition(() => {
  const app = createElement(StrictMode, null, createElement(HydratedRouter));
  if (document.documentElement.hasAttribute("data-static-404")) {
    // The static error document was rendered at /404, but Pages serves it at
    // any missing URL. Render using the real location instead of hydrating
    // URL-dependent markup (such as the active navigation links).
    createRoot(document).render(app);
  } else {
    hydrateRoot(document, app);
  }
});
