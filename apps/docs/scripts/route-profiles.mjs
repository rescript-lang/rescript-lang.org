export const routeProfiles = [
  { id: "homepage", family: "homepage", path: "/", htmlSource: "prerendered" },
  {
    id: "docs-introduction",
    family: "documentation",
    path: "/docs/manual/introduction",
    htmlSource: "prerendered",
  },
  {
    id: "api-stdlib-array",
    family: "documentation",
    path: "/docs/manual/api/stdlib/array",
    htmlSource: "prerendered",
  },
  {
    id: "blog-index",
    family: "blog",
    path: "/blog",
    htmlSource: "prerendered",
  },
  {
    id: "blog-current-article",
    family: "blog",
    path: "/blog/reactive-analysis",
    htmlSource: "prerendered",
  },
  {
    id: "community-overview",
    family: "community",
    path: "/community/overview",
    htmlSource: "prerendered",
  },
  {
    id: "packages",
    family: "packages",
    path: "/packages",
    htmlSource: "prerendered",
  },
  {
    id: "syntax-lookup",
    family: "syntax",
    path: "/syntax-lookup",
    htmlSource: "prerendered",
  },
  {
    id: "playground",
    family: "playground",
    path: "/try",
    htmlSource: "runtime",
  },
  { id: "brand", family: "control", path: "/brand", htmlSource: "prerendered" },
  {
    id: "not-found",
    family: "control",
    path: "/__route-profile-not-found",
    htmlSource: "prerendered",
  },
];

export const nonHomepageRouteProfiles = routeProfiles.filter(
  (profile) => profile.id !== "homepage",
);

export function profileUrl(origin, profile) {
  return new URL(profile.path, origin).href;
}

export function profileHtmlPath(profile) {
  const relativePath = profile.path.replace(/^\/+|\/+$/g, "");
  return relativePath === "" ? "index.html" : `${relativePath}/index.html`;
}

function lighthouseEnvironment(origin) {
  return `LIGHTHOUSE_URLS<<EOF\n${routeProfiles
    .map((profile) => profileUrl(origin, profile))
    .join("\n")}\nEOF`;
}

if (
  process.argv[1] &&
  import.meta.url === new URL(process.argv[1], "file:").href
) {
  if (process.argv[2] !== "lighthouse-urls" || !process.argv[3]) {
    throw new Error("Usage: route-profiles.mjs lighthouse-urls <origin>");
  }
  console.log(lighthouseEnvironment(process.argv[3]));
}
