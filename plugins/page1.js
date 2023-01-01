
import { fetch } from 'undici';
import dotenv from "dotenv";
dotenv.config();

async function plugin(app) {
app.decorateRequest('user', '')

app.addHook('preHandler', async (req, rep) => {
  let res = ''
  if (process.env.DEVELOPMENT)  {
    res = await fetch('http://127.0.0.1:3000/json')
  } else {
    res = await fetch('https://example.com/json')
  }

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
