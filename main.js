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

import fp from 'fastify-plugin'

fastify.register(fp((app, {}, done)  => {
  app.decorate('foo', function () {
    return "{ message: 'hello hi' }"
  })
  done()
}))

fastify.register(autoload, {
    dir: path.join(__dirname, "plugins"),
});

fastify.get("/", async (req, rep) => {
    return rep.view("/views/index.liquid", { world: "world" });
});

fastify.get("/json", async (req, rep) => {
    return {  hello: "world" }
});

fastify.listen(process.env.PORT, "0.0.0.0", console.log);
