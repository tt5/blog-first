import {read} from 'to-vfile'
import {unified} from 'unified'
import rehypeParse from 'rehype-parse'
import rehypeDocument from 'rehype-document'
import rehypeStringify from 'rehype-stringify'
import rehypePrism from '@mapbox/rehype-prism'

main()

async function main() {
  const file = await unified()
    .use(rehypeParse, {fragment: true})
    .use(rehypePrism)
    .use(rehypeStringify)
    .process(await read(process.argv[2]))

  console.log(String(file))
}
