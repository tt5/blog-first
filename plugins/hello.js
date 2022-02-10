import { fetch } from 'undici';

async function hello(app) {
////async function plugin(app) {
//  app.addHook('preHandler', async (req, rep) => {
//    const res = await fetch('http://127.0.0.1:3000/json')
//    const json = await res.json()
//    req.user = json
//  })

  app.get("/hello", async (req, rep) => {
  //const some = app.foo()
  const some = "{ message: 'hello hi' }"
        //return rep.view(`/views/page1/page1.liquid`, { some2: req.user.hello, title: name, some: some });
        return rep.view(`/views/page1.liquid`, { some2: "hello", title: "page1", some: some });
    });
}
export default hello;
