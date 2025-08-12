/*
 * This script is used for generating the search index of the Belt API
 * Ideally we would like following information:
 *
 * - Module names (h1)
 *   - function names (```res sig)
 */
import glob from "glob"
import path from "path"
import fs from "fs"
import { URL } from "url"

import { defaultProcessor } from "./markdown.js"

const pathname = new URL(".", import.meta.url).pathname
const __dirname =
  process.platform !== "win32" ? pathname : pathname.substring(1)

const processFile = (filepath) => {
  const content = fs.readFileSync(filepath, "utf8")
  const result = defaultProcessor.processSync(content)

  const pagesPath = path.resolve("./pages")
  const relFilepath = path.relative(pagesPath, filepath)
  const parsedPath = path.parse(relFilepath)

  const dataset = {
    headers: result.data.headers,
    signatures: result.data.codeblocks.re,
    href: path.join(parsedPath.dir, parsedPath.name),
    moduleName: result.data.mainHeader,
  }
  return dataset
}

const createIndex = (result) => {
  // Currently we reorder the data to a map, the key is
  // reflected as the router pathname, as defined by the
  // NextJS router
  return result.reduce((acc, data) => {
    const { signatures = [], moduleName, headers } = data

    // Sort the headers, but keep type `t` as the first header.
    const headersSorted = [...headers].sort((headerA, headerB) => {
      if (headerA.name === "t") {
        return -1
      } else if (headerB.name === "t") {
        return 1
      } else {
        return headerA.name.localeCompare(headerB.name)
      }
    })

    acc["/" + data.href] = {
      moduleName,
      headers: headersSorted,
    }

    return acc
  }, {})
}

const extractApiIndex = (version) => {
  const versionLabel = version.replace(/\./g, "")
  const VERSION_DIR = path.join(
    __dirname,
    "../pages/docs/manual",
    version,
    "api",
  )
  const BELT_MD_DIR = path.join(VERSION_DIR, "belt")
  const BELT_INDEX_FILE = path.join(
    __dirname,
    `../index_data/${versionLabel}_belt_api_index.json`,
  )
  const beltFiles = glob.sync(`${BELT_MD_DIR}/*.md?(x)`)
  const beltResult = beltFiles.map(processFile)
  const beltIndex = createIndex(beltResult)

  fs.writeFileSync(BELT_INDEX_FILE, JSON.stringify(beltIndex), "utf8")

  const JS_MD_DIR = path.join(VERSION_DIR, "js")
  const JS_INDEX_FILE = path.join(
    __dirname,
    `../index_data/${versionLabel}_js_api_index.json`,
  )
  const jsFiles = glob.sync(`${JS_MD_DIR}/*.md?(x)`)
  const jsResult = jsFiles.map(processFile)
  const jsIndex = createIndex(jsResult)
  fs.writeFileSync(JS_INDEX_FILE, JSON.stringify(jsIndex), "utf8")

  const DOM_MD_DIR = path.join(VERSION_DIR, "dom")
  const DOM_INDEX_FILE = path.join(
    __dirname,
    `../index_data/${versionLabel}_dom_api_index.json`,
  )
  const domFiles = glob
    .sync(`${DOM_MD_DIR}/*.md?(x)`)
    .concat(DOM_MD_DIR + ".mdx")
  const domResult = domFiles.map(processFile)
  const domIndex = createIndex(domResult)

  fs.writeFileSync(DOM_INDEX_FILE, JSON.stringify(domIndex), "utf8")
}

// For versions > 10, please use gendocs.res
extractApiIndex("v10.0.0")
extractApiIndex("v9.0.0")
extractApiIndex("v8.0.0")
