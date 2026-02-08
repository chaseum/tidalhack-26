import { createServer } from "./server";
import { config } from "./env";

const app = createServer();

app.listen(config.PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`gateway listening on ${config.PORT}`);
});
