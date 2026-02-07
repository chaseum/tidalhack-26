import { createServer } from "./server";

const port = Number(process.env.PORT ?? 8080);
const app = createServer();

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`gateway listening on ${port}`);
});
