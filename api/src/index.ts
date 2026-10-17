import { AlmacenD1 } from "./almacen_d1";
import { manejar, type Entorno } from "./manejador";

interface Env extends Entorno {
  DB: D1Database;
  ASSETS: Fetcher;
}

export default {
  fetch: (request, env) => manejar(request, env, new AlmacenD1(env.DB)),
} satisfies ExportedHandler<Env>;
