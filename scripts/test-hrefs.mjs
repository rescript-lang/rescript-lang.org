import remarkValidateLinks from 'remark-validate-links'
import { remark } from 'remark'
import { read } from 'to-vfile'
import { reporter } from 'vfile-reporter'
import * as fs from 'fs/promises'

const files = new Set(...[(await fs.readdir('markdown-pages', { recursive: true }))])

for (const file of files) {

  if (file.includes(".mdx")) {
    // console.log(file.name)

    // let filePath = file.parentPath + '/' + file.name

    let result = await remark()
      .use(remarkValidateLinks)
      .process(await read('markdown-pages/' + file))

    console.log(reporter(result))
  }
}



