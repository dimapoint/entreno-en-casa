export const MAXIMO_REGISTROS = 500;
export const MAXIMO_CUERPO_BYTES = 1024 * 1024;
export const MAXIMO_DATOS_BYTES = 64 * 1024;
export const MAXIMO_LARGO_ID = 100;

const TIPOS = ["sesion", "medicion", "ajustes"] as const;

export type TipoRegistro = (typeof TIPOS)[number];

export interface Registro {
  id: string;
  tipo: TipoRegistro;
  datos: Record<string, unknown>;
  actualizado: number;
  borrado: boolean;
}

export type Resultado<Valor> = { ok: true; valor: Valor } | { ok: false; error: string };

const bytesDe = (texto: string) => new TextEncoder().encode(texto).length;

function esObjeto(valor: unknown): valor is Record<string, unknown> {
  return typeof valor === "object" && valor !== null && !Array.isArray(valor);
}

function esTipo(valor: unknown): valor is TipoRegistro {
  return TIPOS.some((tipo) => tipo === valor);
}

export function validarRegistro(entrada: unknown, posicion: number): Resultado<Registro> {
  const invalido = (motivo: string): Resultado<Registro> => ({
    ok: false,
    error: `El registro ${posicion} no es válido: ${motivo}`,
  });

  if (!esObjeto(entrada)) return invalido("tiene que ser un objeto.");
  const { id, tipo, datos, actualizado, borrado } = entrada;

  if (typeof id !== "string" || id.length < 1 || id.length > MAXIMO_LARGO_ID) {
    return invalido(`el id tiene que ser un texto de 1 a ${MAXIMO_LARGO_ID} caracteres.`);
  }
  if (!esTipo(tipo)) return invalido(`el tipo tiene que ser ${TIPOS.join(", ")}.`);
  if (!esObjeto(datos)) return invalido("los datos tienen que ser un objeto.");
  if (bytesDe(JSON.stringify(datos)) > MAXIMO_DATOS_BYTES) {
    return invalido(`los datos pasan los ${MAXIMO_DATOS_BYTES / 1024} KB.`);
  }
  if (typeof actualizado !== "number" || !Number.isSafeInteger(actualizado) || actualizado <= 0) {
    return invalido("actualizado tiene que ser un entero positivo en milisegundos.");
  }
  if (typeof borrado !== "boolean") return invalido("borrado tiene que ser verdadero o falso.");

  return { ok: true, valor: { id, tipo, datos, actualizado, borrado } };
}

export function validarCuerpo(cuerpo: unknown): Resultado<Registro[]> {
  if (!esObjeto(cuerpo) || !Array.isArray(cuerpo["registros"])) {
    return { ok: false, error: 'El cuerpo tiene que ser un objeto con la lista "registros".' };
  }
  const entradas: unknown[] = cuerpo["registros"];
  if (entradas.length > MAXIMO_REGISTROS) {
    return { ok: false, error: `Se pueden enviar como máximo ${MAXIMO_REGISTROS} registros por pedido.` };
  }

  const registros: Registro[] = [];
  for (const [indice, entrada] of entradas.entries()) {
    const resultado = validarRegistro(entrada, indice + 1);
    if (!resultado.ok) return resultado;
    registros.push(resultado.valor);
  }
  return { ok: true, valor: registros };
}
