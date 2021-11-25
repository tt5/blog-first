async function plugin(fastify, opts) {
    const name = "page1";
    fastify.get("/" + name, async (req, rep) => {
        return rep.view(`/views/${name}.liquid`, { title: name });
    });
}

export default plugin;
