// @ts-check
import fs from "fs";
import webpack from "webpack";
import rehypeSlug from "rehype-slug";
import remarkGfm from "remark-gfm";
import remarkComment from "remark-comment";
import remarkFrontmatter from "remark-frontmatter";
import remarkMdxFrontmatter from "remark-mdx-frontmatter";
import { createLoader } from "simple-functional-loader";

const bsconfig = JSON.parse(fs.readFileSync("./rescript.json").toString());

const { ProvidePlugin } = webpack;

const transpileModules = ["rescript"].concat(bsconfig["bs-dependencies"]);

const config = {
  output: "export",
  pageExtensions: ["jsx", "js", "bs.js", "mdx", "mjs"],
  env: {
    ENV: process.env.NODE_ENV,
    VERSION_LATEST: process.env.VERSION_LATEST,
    VERSION_NEXT: process.env.VERSION_NEXT,
  },
  swcMinify: false,
  webpack: (config, options) => {
    const { isServer } = options;
    if (!isServer) {
      // We shim fs for things like the blog slugs component
      // where we need fs access in the server-side part
      config.resolve.fallback = {
        fs: false,
        path: false,
      };
    }
    // We need this additional rule to make sure that mjs files are
    // correctly detected within our src/ folder
    config.module.rules.push({
      test: /\.m?js$/,
      // v-- currently using an experimental setting with esbuild-loader
      //use: options.defaultLoaders.babel,
      use: [{ loader: "esbuild-loader", options: { loader: "jsx" } }],
      exclude: /node_modules/,
      type: "javascript/auto",
      resolve: {
        fullySpecified: false,
      },
    });

    function mainMdxLoader(plugins) {
      return [
        createLoader(function(source) {
          const result = `${source}\n\nMDXContent.frontmatter = frontmatter`;
          return result;
        }),
      ];
    }

    config.module.rules.push({
      test: /\.mdx?$/,
      use: mainMdxLoader(),
    });

    config.module.rules.push({
      test: /\.mdx?$/,
      use: [
        {
          loader: "@mdx-js/loader",
          /** @type {import('@mdx-js/loader').Options} */
          options: {
            remarkPlugins: [
              remarkComment,
              remarkGfm,
              remarkFrontmatter,
              remarkMdxFrontmatter,
            ],
            providerImportSource: "@mdx-js/react",
            rehypePlugins: [rehypeSlug],
          },
        },
      ],
    });

    config.plugins.push(new ProvidePlugin({ React: "react" }));
    return config;
  },
};

export default {
  transpilePackages: transpileModules,
  ...config,
};
