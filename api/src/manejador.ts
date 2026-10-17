import type { Almacen } from "./almacen";
import { codigoCorrecto, extraerCodigo } from "./autenticacion";
import { MAXIMO_CUERPO_BYTES, validarCuerpo } from "./validacion";

export interface Entorno {
  TOKEN?: string | undefined;
}

const RUTA = "/api/registros";
const METODOS = "GET, PUT, OPTIONS";

// El token viaja en la cabecera Authorization y no en cookies, por eso el origen abierto no expone nada.
const CABECERAS_COMUNES = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": METODOS,
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Max-Age": "86400",
  "Cache-Control": "no-store",
};

function responder(estado: number, cuerpo?: unknown, extra: Record<string, string> = {}): Response {
  const cabeceras = { ...CABECERAS_COMUNES, ...extra };
  if (cuerpo === undefined) return new Response(null, { status: estado, headers: cabeceras });
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { ...cabeceras, "Content-Type": "application/json; charset=utf-8" },
  });
}

const fallar = (estado: number, mensaje: string, extra?: Record<string, string>) =>
  responder(estado, { error: mensaje }, extra);

/** Lee el cuerpo cortando apenas pasa el máximo, sin confiar en Content-Length. Devuelve null si se pasa. */
async function leerCuerpoLimitado(request: Request): Promise<string | null> {
  if (Number(request.headers.get("Content-Length")) > MAXIMO_CUERPO_BYTES) return null;
  const lector = request.body?.getReader();
  if (!lector) return "";

  const partes: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    const { done, value } = await lector.read();
    if (done) break;
    total += value.byteLength;
    if (total > MAXIMO_CUERPO_BYTES) {
      await lector.cancel();
      return null;
    }
    partes.push(value);
  }
  return new Blob(partes).text();
}

async function rechazarSiNoAutorizado(request: Request, env: Entorno): Promise<Response | null> {
  if (!env.TOKEN) return fallar(500, "El servidor no tiene configurado el secreto TOKEN.");
  const recibido = extraerCodigo(request.headers.get("Authorization"));
  if (recibido === null || !(await codigoCorrecto(recibido, env.TOKEN))) {
    return fallar(401, "Falta el código de sincronización o no es correcto.", { "WWW-Authenticate": "Bearer" });
  }
  return null;
}

async function recibirRegistros(request: Request, almacen: Almacen): Promise<Response> {
  const texto = await leerCuerpoLimitado(request);
  if (texto === null) return fallar(400, "El cuerpo pasa el máximo de 1 MB.");

  let cuerpo: unknown;
  try {
    cuerpo = JSON.parse(texto);
  } catch {
    return fallar(400, "El cuerpo no es un JSON válido.");
  }

  const validado = validarCuerpo(cuerpo);
  if (!validado.ok) return fallar(400, validado.error);

  // aceptados cuenta las filas escritas de verdad: las que llegaron más viejas o iguales a lo guardado no suman.
  return responder(200, { aceptados: await almacen.guardar(validado.valor) });
}

export async function manejar(request: Request, env: Entorno, almacen: Almacen): Promise<Response> {
  if (new URL(request.url).pathname !== RUTA) return fallar(404, "Esa ruta no existe.");
  if (request.method === "OPTIONS") return responder(204);
  if (request.method !== "GET" && request.method !== "PUT") {
    return fallar(405, "Método no permitido. Usá GET o PUT.", { Allow: METODOS });
  }

  try {
    const rechazo = await rechazarSiNoAutorizado(request, env);
    if (rechazo) return rechazo;
    if (request.method === "GET") return responder(200, { registros: await almacen.listar() });
    return await recibirRegistros(request, almacen);
  } catch (error) {
    console.error("Falló el pedido a /api/registros", error);
    return fallar(500, "Error interno del servidor.");
  }
}
