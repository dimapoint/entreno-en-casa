# API de sincronización

Un Worker de Cloudflare con una base D1. Guarda las sesiones, mediciones y ajustes de la app y, desde el mismo origen, sirve el build web de Flutter (`../build/web`). Así la web no necesita CORS ni configuración de URL.

## Contrato

Todo va por `/api/registros` con la cabecera `Authorization: Bearer <TOKEN>`. Sin código o con uno incorrecto responde 401. Si el servidor no tiene el secreto configurado responde 500 y no deja pasar a nadie.

- `GET` devuelve `{"registros":[{"id","tipo","datos","actualizado","borrado"}]}`.
- `PUT` recibe `{"registros":[...]}` con esa misma forma y devuelve `{"aceptados":N}`. `N` es la cantidad de filas que se escribieron de verdad: las que llegan con un `actualizado` menor o igual al guardado se ignoran y no suman.
- Gana el último en escribir: un registro solo pisa a otro con el mismo `id` si su `actualizado` es mayor.
- Los borrados quedan como marca (`borrado: true`). Nunca se eliminan filas.
- Límites: 500 registros por pedido, `id` de 1 a 100 caracteres, `tipo` `sesion`, `medicion` o `ajustes`, `datos` de hasta 64 KB y cuerpo de hasta 1 MB. Si algo no cumple, 400 con `{"error":"..."}`.

## Probar en tu máquina

```sh
bun install
bunx wrangler d1 migrations apply entreno-en-casa --local
echo TOKEN=un-codigo-de-prueba > .dev.vars   # el archivo está ignorado por git
bun run dev
```

Wrangler necesita que exista `../build/web`. Si todavía no compilaste la web, creá esa carpeta con un `index.html` cualquiera.

Los tests y el chequeo de tipos no necesitan nada de eso:

```sh
bun test
bun run typecheck
```

## Publicar

1. `bun install`
2. `bunx wrangler login`
3. `bunx wrangler d1 create entreno-en-casa` y copiá el `database_id` que devuelve en `wrangler.jsonc`, reemplazando el de relleno.
4. `bunx wrangler d1 migrations apply entreno-en-casa --remote`
5. `bunx wrangler secret put TOKEN` y pegá un código largo y difícil de adivinar. Ese mismo código se carga en la app como código de sincronización.
6. Desde la raíz del proyecto: `flutter build web --release`
7. En `api/`: `bun run deploy`

Para que la app de Android hable con el Worker, compilala con `--dart-define=API_URL=https://entreno-en-casa.<tu-subdominio>.workers.dev`.
