import { describe, expect, test } from "bun:test";
import { codigoCorrecto, extraerCodigo } from "../src/autenticacion";

describe("codigoCorrecto", () => {
  test("acepta el código idéntico", async () => {
    expect(await codigoCorrecto("secreto-largo", "secreto-largo")).toBe(true);
  });

  test("rechaza uno distinto, uno más corto, uno más largo y uno vacío", async () => {
    expect(await codigoCorrecto("secreto-largX", "secreto-largo")).toBe(false);
    expect(await codigoCorrecto("secreto", "secreto-largo")).toBe(false);
    expect(await codigoCorrecto("secreto-largo-y-más", "secreto-largo")).toBe(false);
    expect(await codigoCorrecto("", "secreto-largo")).toBe(false);
  });
});

describe("extraerCodigo", () => {
  test("lee el esquema Bearer sin importar mayúsculas", () => {
    expect(extraerCodigo("Bearer abc123")).toBe("abc123");
    expect(extraerCodigo("bearer abc123")).toBe("abc123");
  });

  test("devuelve null si falta o no es Bearer", () => {
    expect(extraerCodigo(null)).toBeNull();
    expect(extraerCodigo("")).toBeNull();
    expect(extraerCodigo("Bearer")).toBeNull();
    expect(extraerCodigo("Basic abc123")).toBeNull();
    expect(extraerCodigo("Bearer dos palabras")).toBeNull();
  });
});
