
import { fetch } from 'undici';

async function plugin(app) {

app.addHook('preHandler', async (req, rep) => {
    const res = await fetch('http://127.0.0.1:3000/json')
    //const res = await fetch('https://jsonplaceholder.cypress.io/todos/1')
    const json = await res.json()
    console.log(json);

  req.user = json
//  rep.send(json)
//  return rep
})

    const name = "page1";
    const some = app.foo()
    app.get("/" + name, async (req, rep) => {
  console.log("LOG: " + req.user.hello)
        return rep.view(`/views/${name}.liquid`, { some2: req.user.hello, title: name, some: some });
    });
}

export default plugin;
