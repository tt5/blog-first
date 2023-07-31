process.chdir(`${process.cwd()}/../..`);
import Fastify from "fastify";
import dotenv from "dotenv";
import { Liquid } from "liquidjs";
import autoload from "@fastify/autoload";
import path from "path";
import { v4 as uuidv4 } from 'uuid';

dotenv.config();
const fastify = Fastify({
  // don't use pino-pretty in production
  // logger: true,
  logger: {
    transport: {
      target: "pino-pretty",
    }
  },
  disableRequestLogging: true,
  genReqId(req) {
    // you get access to the req here if you need it - must be a synchronous function
    return uuidv4();
  },
});

const now = () => Date.now();

fastify.addHook("onRequest", (req, reply, done) => {
  reply.startTime = now();
  req.log.info({ url: req.raw.url }, "received request");
  done();
});

fastify.addHook("onResponse", (req, reply, done) => {
  req.log.info(
    {
      url: req.raw.url, // add url to response as well for simple correlating
      statusCode: reply.raw.statusCode,
      durationMs: now() - reply.startTime, // recreate duration in ms - use process.hrtime() - https://nodejs.org/api/process.html#process_process_hrtime_bigint for most accuracy
    },
    "request completed"
  );
  done();
});

const __dirname = path.resolve(path.dirname(""));
const engine = new Liquid({
  root: path.join(__dirname, "views"),
  extname: ".liquid",
});

fastify.register(import("@fastify/view"), {
  engine: {
    liquid: engine,
  },
});

fastify.register(import("@fastify/static"), {
  root: path.join(__dirname, "public"),
  prefix: "/public/",
});

import fp from "fastify-plugin";

fastify.register(
  fp((app, {}, done) => {
    app.decorate("foo", function () {
      return "{ message: 'hello hi' }";
    });
    done();
  })
);

fastify.register(autoload, {
  dir: path.join(__dirname, "plugins"),
});

fastify.get("/", async (req, rep) => {
  return rep.view("/views/index.liquid", { title: "tt5" });
});

fastify.get("/json", async (req, rep) => {
  return { hello: "world" };
});

fastify.listen(process.env.PORT, "0.0.0.0", console.log);

["SIGINT", "SIGTERM"].forEach((signal) => {
  process.on(signal, async () => {
    await fastify.close();
    console.log("\nbye");
    process.exit(0);
  })
})
