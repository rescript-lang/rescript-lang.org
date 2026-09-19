import babel from "@rolldown/plugin-babel";
import { reactCompilerPreset } from "@vitejs/plugin-react";

export function homepageCompilerOptions() {
  return {
    include:
      /[/\\]apps[/\\]docs[/\\]app[/\\]routes[/\\]LandingPage[^/\\]*\.jsx(?:$|\?)/,
    exclude: [/[/\\]node_modules[/\\]/, /^\0rolldown\/runtime\.js$/],
    presets: [
      // Keep the preset's client-only guard and React 19 runtime optimization.
      reactCompilerPreset({ compilationMode: "annotation", target: "19" }),
    ],
  };
}

export function homepageReactCompiler() {
  return babel(homepageCompilerOptions());
}
