import { describe, expect, test } from "bun:test";
import { validarCuerpo, validarRegistro, type Registro } from "../src/validacion";

const valido = {
  id: "sesion-2026-10-01",
  tipo: "sesion",
  datos: { semana: 1 },
  actualizado: 1_700_000_000_000,
  borrado: false,
} satisfies Registro;

// test.each reparte los arrays como argumentos sueltos, así que cada caso va envuelto.
const comoCasos = (valores: unknown[]) => valores.map((valor) => [valor]);

const conCambio =(cambios: Record<string, unknown>) => ({ ...valido, ...cambios });

function errorDe(entrada: unknown): string {
  const resultado = validarRegistro(entrada, 1);
  if (resultado.ok) throw new Error("Se esperaba un error de validación");
  return resultado.error;
}

describe("validarRegistro", () => {
  test("acepta un registro completo y los tres tipos", () => {
    const resultado = validarRegistro(valido, 1);
    expect(resultado.ok && resultado.valor).toEqual(valido);
    for (const tipo of ["sesion", "medicion", "ajustes"]) {
      expect(validarRegistro(conCambio({ tipo }), 1).ok).toBe(true);
    }
  });

  test("acepta borrado verdadero", () => {
    expect(validarRegistro(conCambio({ borrado: true }), 1).ok).toBe(true);
  });

  test.each(comoCasos([null, "texto", 7, [valido]]))("rechaza que el registro sea %p", (entrada) => {
    expect(errorDe(entrada)).toContain("tiene que ser un objeto");
  });

  test.each([undefined, null, 5, "", "x".repeat(101), {}])("rechaza el id %p", (id) => {
    expect(errorDe(conCambio({ id }))).toContain("id");
  });

  test("acepta ids de 1 y de 100 caracteres", () => {
    expect(validarRegistro(conCambio({ id: "a" }), 1).ok).toBe(true);
    expect(validarRegistro(conCambio({ id: "a".repeat(100) }), 1).ok).toBe(true);
  });

  test.each([undefined, "", "otro", "SESION", 1, null])("rechaza el tipo %p", (tipo) => {
    expect(errorDe(conCambio({ tipo }))).toContain("tipo");
  });

  test.each(comoCasos([undefined, null, [], [1, 2], "texto", 3, true]))("rechaza los datos %p", (datos) => {
    expect(errorDe(conCambio({ datos }))).toContain("datos");
  });

  test("los datos aceptan hasta 64 KB exactos y rechazan un byte más", () => {
    // {"texto":""} ocupa 12 bytes, el resto es relleno.
    expect(validarRegistro(conCambio({ datos: { texto: "a".repeat(65_536 - 12) } }), 1).ok).toBe(true);
    expect(errorDe(conCambio({ datos: { texto: "a".repeat(65_536 - 12 + 1) } }))).toContain("64 KB");
  });

  test("los datos se miden en bytes y no en caracteres", () => {
    expect(errorDe(conCambio({ datos: { texto: "ñ".repeat(32_768) } }))).toContain("64 KB");
  });

  test.each([undefined, null, 0, -5, 1.5, "1700000000000", Number.NaN, Infinity, 2 ** 53])(
    "rechaza actualizado %p",
    (actualizado) => {
      expect(errorDe(conCambio({ actualizado }))).toContain("actualizado");
    },
  );

  test.each([undefined, null, 0, 1, "true"])("rechaza borrado %p", (borrado) => {
    expect(errorDe(conCambio({ borrado }))).toContain("borrado");
  });

  test("el mensaje dice qué número de registro falló", () => {
    expect(errorDe({}).startsWith("El registro 1 ")).toBe(true);
    const resultado = validarRegistro({}, 7);
    expect(resultado.ok === false && resultado.error.startsWith("El registro 7 ")).toBe(true);
  });
});

describe("validarCuerpo", () => {
  test.each(comoCasos([null, "texto", [], {}, { registros: null }, { registros: {} }]))("rechaza el cuerpo %p", (cuerpo) => {
    expect(validarCuerpo(cuerpo).ok).toBe(false);
  });

  test("acepta una lista vacía", () => {
    expect(validarCuerpo({ registros: [] })).toEqual({ ok: true, valor: [] });
  });

  test("acepta 500 registros y rechaza 501", () => {
    const armar = (cantidad: number) => ({
      registros: Array.from({ length: cantidad }, (_ignorado, indice) => conCambio({ id: `registro-${indice}` })),
    });
    expect(validarCuerpo(armar(500)).ok).toBe(true);
    const rechazo = validarCuerpo(armar(501));
    expect(rechazo.ok === false && rechazo.error).toContain("500");
  });

  test("frena en el primer registro inválido e indica cuál es", () => {
    const resultado = validarCuerpo({ registros: [valido, conCambio({ id: "" }), valido] });
    expect(resultado.ok === false && resultado.error).toContain("El registro 2 ");
  });
});
