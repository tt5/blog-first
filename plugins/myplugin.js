async function plugin (fastify, opts) {
  fastify.get('/helloworld', async (req, reply) => {
    return { hello: 'world' }
  })
}

export default plugin
