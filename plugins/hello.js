import { fetch } from "undici";

async function hello(app) {
  app.get("/hello", async (req, rep) => {
    //const some = app.foo()
    const some = "{ message: 'hello hi2' }";
    //return rep.view(`/views/page1/page1.liquid`, { some2: req.user.hello, title: name, some: some });
    return rep.view(`/views/page1.liquid`, {
      some2: "hello",
      title: "page1",
      some: some,
    });
  });
}
export default hello;
