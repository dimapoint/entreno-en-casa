import { beforeEach, describe, expect, test } from "bun:test";
import { manejar, type Entorno } from "../src/manejador";
import type { Registro } from "../src/validacion";
import { AlmacenMemoria } from "./almacen_memoria";

const CODIGO = "codigo-de-prueba";
const URL_REGISTROS = "http://localhost/api/registros";

const registro = (cambios: Partial<Registro> = {}): Registro => ({
  id: "sesion-2026-10-01",
  tipo: "sesion",
  datos: { semana: 1, series: [10, 12, 15] },
  actualizado: 1_000,
  borrado: false,
  ...cambios,
});

let almacen: AlmacenMemoria;

beforeEach(() => {
  almacen = new AlmacenMemoria();
});

interface Opciones {
  entorno?: Entorno;
  cabeceras?: Record<string, string>;
  cuerpo?: BodyInit;
  ruta?: string;
}

function pedir(metodo: string, opciones: Opciones = {}): Promise<Response> {
  const { entorno = { TOKEN: CODIGO }, cabeceras = { Authorization: `Bearer ${CODIGO}` }, cuerpo, ruta } = opciones;
  const init: RequestInit = { method: metodo, headers: cabeceras };
  if (cuerpo !== undefined) init.body = cuerpo;
  return manejar(new Request(ruta ?? URL_REGISTROS, init), entorno, almacen);
}

const enviar = (registros: Registro[], opciones: Opciones = {}) =>
  pedir("PUT", { ...opciones, cuerpo: JSON.stringify({ registros }) });

async function leer(respuesta: Response): Promise<Registro[]> {
  return ((await respuesta.json()) as { registros: Registro[] }).registros;
}

describe("autenticación", () => {
  test("sin cabecera Authorization devuelve 401 y no toca el almacén", async () => {
    const respuesta = await enviar([registro()], { cabeceras: {} });
    expect(respuesta.status).toBe(401);
    expect(await respuesta.json()).toEqual({ error: expect.any(String) });
    expect(almacen.filas.size).toBe(0);
  });

  test.each(["Bearer otro-codigo", `Basic ${CODIGO}`, "Bearer ", CODIGO])("rechaza la cabecera %p", async (cabecera) => {
    expect((await pedir("GET", { cabeceras: { Authorization: cabecera } })).status).toBe(401);
  });

  test("sin secreto configurado responde 500 aunque el pedido traiga código", async () => {
    for (const entorno of [{}, { TOKEN: "" }, { TOKEN: undefined }]) {
      const respuesta = await pedir("GET", { entorno });
      expect(respuesta.status).toBe(500);
      expect(((await respuesta.json()) as { error: string }).error).toContain("TOKEN");
    }
  });

  test("sin secreto tampoco deja pasar un PUT", async () => {
    expect((await enviar([registro()], { entorno: {} })).status).toBe(500);
    expect(almacen.filas.size).toBe(0);
  });
});

describe("OPTIONS y cabeceras", () => {
  test("OPTIONS responde 204 sin pedir código y con las cabeceras de CORS", async () => {
    const respuesta = await pedir("OPTIONS", { cabeceras: {}, entorno: {} });
    expect(respuesta.status).toBe(204);
    expect(await respuesta.text()).toBe("");
    expect(respuesta.headers.get("Access-Control-Allow-Origin")).toBe("*");
    expect(respuesta.headers.get("Access-Control-Allow-Methods")).toBe("GET, PUT, OPTIONS");
    expect(respuesta.headers.get("Access-Control-Allow-Headers")).toBe("Authorization, Content-Type");
  });

  test("todas las respuestas llevan CORS y Cache-Control no-store", async () => {
    const respuestas = [
      await pedir("GET"),
      await pedir("GET", { cabeceras: {} }),
      await pedir("POST"),
      await pedir("GET", { ruta: "http://localhost/api/otra" }),
      await pedir("OPTIONS"),
      await pedir("GET", { entorno: {} }),
    ];
    for (const respuesta of respuestas) {
      expect(respuesta.headers.get("Access-Control-Allow-Origin")).toBe("*");
      expect(respuesta.headers.get("Cache-Control")).toBe("no-store");
    }
  });
});

describe("GET /api/registros", () => {
  test("vacío devuelve una lista vacía en JSON", async () => {
    const respuesta = await pedir("GET");
    expect(respuesta.status).toBe(200);
    expect(respuesta.headers.get("Content-Type")).toContain("application/json");
    expect(await respuesta.json()).toEqual({ registros: [] });
  });
});

describe("PUT /api/registros", () => {
  test("guarda y el GET devuelve lo mismo", async () => {
    const enviados = [
      registro(),
      registro({ id: "medicion-1", tipo: "medicion", datos: { pesoGramos: 70_500 }, actualizado: 2_000 }),
    ];
    const respuesta = await enviar(enviados);
    expect(respuesta.status).toBe(200);
    expect(await respuesta.json()).toEqual({ aceptados: 2 });
    expect(await leer(await pedir("GET"))).toEqual(enviados);
  });

  test("acepta una lista vacía", async () => {
    const respuesta = await enviar([]);
    expect(respuesta.status).toBe(200);
    expect(await respuesta.json()).toEqual({ aceptados: 0 });
  });

  test("el último en escribir gana: un actualizado mayor pisa", async () => {
    await enviar([registro({ datos: { version: "vieja" }, actualizado: 1_000 })]);
    const respuesta = await enviar([registro({ datos: { version: "nueva" }, actualizado: 2_000 })]);
    expect(await respuesta.json()).toEqual({ aceptados: 1 });
    expect(await leer(await pedir("GET"))).toEqual([registro({ datos: { version: "nueva" }, actualizado: 2_000 })]);
  });

  test("un registro más viejo o igual no pisa y no cuenta como aceptado", async () => {
    await enviar([registro({ datos: { version: "actual" }, actualizado: 2_000 })]);
    for (const actualizado of [1_000, 2_000]) {
      const respuesta = await enviar([registro({ datos: { version: "intruso" }, actualizado })]);
      expect(await respuesta.json()).toEqual({ aceptados: 0 });
    }
    expect(await leer(await pedir("GET"))).toEqual([registro({ datos: { version: "actual" }, actualizado: 2_000 })]);
  });

  test("el borrado se guarda como marca y la fila sigue existiendo", async () => {
    await enviar([registro({ actualizado: 1_000 })]);
    await enviar([registro({ borrado: true, actualizado: 2_000 })]);
    expect(await leer(await pedir("GET"))).toEqual([registro({ borrado: true, actualizado: 2_000 })]);
    expect(almacen.filas.size).toBe(1);
  });

  test("un registro viejo no revive un borrado, uno nuevo sí", async () => {
    await enviar([registro({ borrado: true, actualizado: 2_000 })]);
    await enviar([registro({ borrado: false, actualizado: 1_000 })]);
    expect((await leer(await pedir("GET")))[0]?.borrado).toBe(true);
    await enviar([registro({ borrado: false, actualizado: 3_000 })]);
    expect((await leer(await pedir("GET")))[0]?.borrado).toBe(false);
  });

  test("con filas mezcladas cuenta solo las escritas", async () => {
    await enviar([registro({ id: "a-1", actualizado: 5_000 })]);
    const respuesta = await enviar([
      registro({ id: "a-1", actualizado: 4_000 }),
      registro({ id: "a-2", actualizado: 4_000 }),
      registro({ id: "a-3", actualizado: 4_000 }),
    ]);
    expect(await respuesta.json()).toEqual({ aceptados: 2 });
  });
});

describe("validación en el borde", () => {
  async function esperarRechazo(respuesta: Response, fragmento: string) {
    expect(respuesta.status).toBe(400);
    const cuerpo = (await respuesta.json()) as { error: string };
    expect(cuerpo.error).toContain(fragmento);
    expect(almacen.filas.size).toBe(0);
  }

  test("JSON roto", async () => {
    await esperarRechazo(await pedir("PUT", { cuerpo: "{no es json" }), "JSON");
  });

  test("cuerpo vacío", async () => {
    await esperarRechazo(await pedir("PUT"), "JSON");
  });

  test("cuerpo sin la lista registros", async () => {
    await esperarRechazo(await pedir("PUT", { cuerpo: "[]" }), "registros");
  });

  test("más de 500 registros", async () => {
    const registros = Array.from({ length: 501 }, (_ignorado, indice) => registro({ id: `registro-${indice}` }));
    await esperarRechazo(await enviar(registros), "500");
  });

  test("un registro inválido corta todo el pedido", async () => {
    const roto = { ...registro({ id: "otro" }), tipo: "desconocido" } as unknown as Registro;
    await esperarRechazo(await enviar([registro(), roto]), "tipo");
  });

  test("cuerpo de más de 1 MB sin Content-Length declarado", async () => {
    const relleno = JSON.stringify({ registros: [], relleno: "a".repeat(1024 * 1024) });
    await esperarRechazo(await pedir("PUT", { cuerpo: relleno }), "1 MB");
  });

  test("cuerpo que declara más de 1 MB en Content-Length", async () => {
    const respuesta = await pedir("PUT", {
      cuerpo: JSON.stringify({ registros: [] }),
      cabeceras: { Authorization: `Bearer ${CODIGO}`, "Content-Length": String(1024 * 1024 + 1) },
    });
    await esperarRechazo(respuesta, "1 MB");
  });
});

describe("rutas y métodos", () => {
  test.each(["POST", "DELETE", "PATCH", "HEAD"])("%s devuelve 405 con Allow", async (metodo) => {
    const respuesta = await pedir(metodo);
    expect(respuesta.status).toBe(405);
    expect(respuesta.headers.get("Allow")).toBe("GET, PUT, OPTIONS");
  });

  test.each(["/api/otra", "/api/registros/", "/api/registros/uno", "/api", "/"])(
    "la ruta %s devuelve 404 JSON",
    async (ruta) => {
      const respuesta = await pedir("GET", { ruta: `http://localhost${ruta}` });
      expect(respuesta.status).toBe(404);
      expect(respuesta.headers.get("Content-Type")).toContain("application/json");
      expect(await respuesta.json()).toEqual({ error: expect.any(String) });
    },
  );
});

describe("fallas internas", () => {
  test("si el almacén falla responde 500 JSON sin filtrar el detalle", async () => {
    const original = console.error;
    console.error = () => {};
    try {
      almacen.listar = () => Promise.reject(new Error("D1 se cayó: detalle interno"));
      const respuesta = await pedir("GET");
      expect(respuesta.status).toBe(500);
      const texto = await respuesta.text();
      expect(texto).toContain("error");
      expect(texto).not.toContain("detalle interno");
    } finally {
      console.error = original;
    }
  });
});
