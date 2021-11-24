import Fastify from "fastify";
import dotenv from "dotenv";
dotenv.config();
import { Liquid } from "liquidjs";
import autoload from "fastify-autoload";
import path from "path";
const fastify = Fastify();
const __dirname = path.resolve(path.dirname(""));
const engine = new Liquid({
    root: path.join(__dirname, "views"),
    extname: ".liquid",
});

fastify.register(import("point-of-view"), {
    engine: {
        liquid: engine,
    },
});

fastify.register(import("fastify-static"), {
    root: path.join(__dirname, "public"),
    prefix: "/public/",
});

fastify.register(autoload, {
    dir: path.join(__dirname, "plugins"),
});

fastify.get("/", async (req, rep) => {
    return rep.view("/views/index.liquid", { world: "world" });
});

fastify.listen(process.env.PORT, "0.0.0.0", console.log);
