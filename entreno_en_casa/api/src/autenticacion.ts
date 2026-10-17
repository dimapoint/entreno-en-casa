const codificador = new TextEncoder();

async function huella(texto: string): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", codificador.encode(texto)));
}

/** Compara las huellas SHA-256 en lugar de los textos, así el tiempo no depende del largo ni del contenido del secreto. */
export async function codigoCorrecto(recibido: string, esperado: string): Promise<boolean> {
  const [huellaRecibida, huellaEsperada] = await Promise.all([huella(recibido), huella(esperado)]);
  let diferencia = 0;
  for (const [indice, byteEsperado] of huellaEsperada.entries()) {
    diferencia |= (huellaRecibida[indice] ?? 0) ^ byteEsperado;
  }
  return diferencia === 0;
}

export function extraerCodigo(cabecera: string | null): string | null {
  return /^Bearer\s+(\S+)$/i.exec(cabecera ?? "")?.[1] ?? null;
}
