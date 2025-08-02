import mdx from '@mdx-js/rollup'
import react from '@vitejs/plugin-react'
import rsc from '@vitejs/plugin-rsc'
import assert from 'node:assert'
import fs from 'node:fs'
import path from 'node:path'
import { Readable } from 'node:stream'
import { pathToFileURL } from 'node:url'
import { defineConfig } from 'vite'
import inspect from 'vite-plugin-inspect'
import { RSC_POSTFIX } from './src/framework/shared.mjs'

export default defineConfig((env) => ({
    plugins: [
        mdx(),
        react(),
        rsc({
            entries: {
                client: './src/framework/entry.browser.jsx',
                rsc: './src/framework/entry.rsc.jsx',
                ssr: './src/framework/entry.ssr.jsx',
            },
            serverHandler: env.isPreview ? false : undefined,
            useBuildAppHook: true,
        }),
        rscSsgPlugin(),
        inspect(),
    ],
}))

function rscSsgPlugin() {
    return [
        {
            name: 'rsc-ssg',
            config(_config, env) {
                if (env.isPreview) {
                    return {
                        appType: 'mpa',
                    }
                }
            },
            buildApp: {
                async handler(builder) {
                    await renderStatic(builder.config)
                },
            },
        },
    ]
}

async function renderStatic(config) {
    // import server entry
    const entryPath = path.join(config.environments.rsc.build.outDir, 'index.js')
    const entry = await import(
        pathToFileURL(entryPath).href
    )

    // entry provides a list of static paths
    const staticPaths = await entry.getStaticPaths()

    console.log(staticPaths)

    // render rsc and html
    const baseDir = config.environments.client.build.outDir
    for (const htmlPath of staticPaths) {
        config.logger.info('[vite-rsc:ssg] -> ' + htmlPath)
        const rscPath = htmlPath + RSC_POSTFIX
        const htmlResponse = await entry.default(
            new Request(new URL(htmlPath, 'http://ssg.local')),
        )
        assert.equal(htmlResponse.status, 200)
        await fs.promises.writeFile(
            path.join(baseDir, normalizeHtmlFilePath(htmlPath)),
            Readable.fromWeb(htmlResponse.body),
        )

        const rscResponse = await entry.default(
            new Request(new URL(rscPath, 'http://ssg.local')),
        )
        assert.equal(rscResponse.status, 200)
        await fs.promises.writeFile(
            path.join(baseDir, rscPath),
            Readable.fromWeb(rscResponse.body),
        )
    }
}

function normalizeHtmlFilePath(p) {
    if (p.endsWith('/')) {
        return p + 'index.html'
    }
    return p + '.html'
}