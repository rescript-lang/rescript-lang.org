import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { index, layout, route } from "@react-router/dev/routes";
import { apiDataDirectory } from "./scripts/api-data.mjs";

function mdxPaths(directory) {
  return readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      if (entry.isDirectory()) {
        return mdxPaths(join(directory, entry.name)).map(
          (path) => `${entry.name}/${path}`,
        );
      }
      return entry.isFile() && entry.name.endsWith(".mdx")
        ? [entry.name.slice(0, -4)]
        : [];
    })
    .sort();
}

// Both React Router and route-type generation read this build-time configuration.
// It can run before ReScript compilation and does not depend on the caller's cwd.
export function loadRoutes({
  contentDirectory = fileURLToPath(
    new URL("./markdown-pages/", import.meta.url),
  ),
  apiDirectory = apiDataDirectory({
    directory: fileURLToPath(new URL("../../data/api/", import.meta.url)),
  }),
} = {}) {
  const apiPaths = (library) =>
    Object.keys(
      JSON.parse(readFileSync(join(apiDirectory, `${library}.json`), "utf8")),
    )
      .filter((key) => key !== library)
      .sort()
      .map((key) => `docs/manual/api/${key}`);
  const stdlibPaths = apiPaths("stdlib");
  const domPaths = apiPaths("dom");
  const beltPaths = apiPaths("belt");
  const apiRoutes = (paths) =>
    paths.map((path) => route(path, "./routes/ApiRoute.jsx", { id: path }));
  const contentRoutes = (prefix, file, include = () => true) =>
    mdxPaths(join(contentDirectory, prefix))
      .map((path) => `${prefix}/${path}`)
      .filter(include)
      .map((path) => route(path, file, { id: path }));

  return {
    stdlibPaths,
    routes: [
      layout("./layouts/HomepageLayoutRoute.jsx", [
        index("./routes/LandingPageRoute.jsx"),
      ]),
      route("try", "./routes/TryRoute.jsx"),
      layout("./layouts/ContentLayoutRoute.jsx", [
        route("packages", "./routes/PackagesRoute.jsx"),
        route("brand", "./routes/BrandRoute.jsx"),
        route("blog", "./routes/BlogRoute.jsx", { id: "blog-index" }),
        route("blog/archived", "./routes/BlogRoute.jsx", {
          id: "blog-archived",
        }),
        ...contentRoutes("blog", "./routes/BlogArticleRoute.jsx"),
        ...contentRoutes("community", "./routes/CommunityRoute.jsx"),
        route("docs", "./routes/DocsOverview.jsx", { id: "docs-overview" }),
        layout("./layouts/DocsLayoutRoute.jsx", [
          route("docs/manual/api", "./routes/ApiOverviewRoute.jsx", {
            id: "api-overview",
          }),
          route("docs/manual/api/stdlib", "./routes/ApiRoute.jsx", {
            id: "api-stdlib",
          }),
          route("docs/manual/api/introduction", "./routes/ApiRoute.jsx", {
            id: "api-intro",
          }),
          route("docs/manual/api/belt", "./routes/ApiRoute.jsx", {
            id: "api-belt",
          }),
          route("docs/manual/api/dom", "./routes/ApiRoute.jsx", {
            id: "api-dom",
          }),
          ...apiRoutes(stdlibPaths),
          ...apiRoutes(beltPaths),
          ...apiRoutes(domPaths),
          ...contentRoutes(
            "docs/manual",
            "./routes/DocsManualRoute.jsx",
            (path) =>
              path !== "docs/manual/api" &&
              !path.startsWith("docs/manual/api/"),
          ),
          ...contentRoutes("docs/guides", "./routes/DocsGuidesRoute.jsx"),
          ...contentRoutes("docs/react", "./routes/DocsReactRoute.jsx"),
          route("syntax-lookup", "./routes/SyntaxLookupRoute.jsx", {
            id: "syntax-lookup",
          }),
          ...contentRoutes(
            "syntax-lookup",
            "./routes/SyntaxLookupDetailRoute.jsx",
          ),
        ]),
      ]),
      route("*", "./routes/NotFoundRoute.jsx"),
    ],
  };
}
