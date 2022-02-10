async function plugin(fastify, opts) {
    const name = "comp1";
    fastify.get("/" + name, async (req, rep) => {
        return rep.view(`/views/pages/${name}.html`, { title: name });
    });
}

export default plugin;
