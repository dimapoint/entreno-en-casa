import type { Almacen } from "../src/almacen";
import type { Registro } from "../src/validacion";

/** Imita la regla de D1: una fila solo se pisa si la entrante tiene un actualizado mayor. */
export class AlmacenMemoria implements Almacen {
  readonly filas = new Map<string, Registro>();

  async listar(): Promise<Registro[]> {
    return structuredClone([...this.filas.values()]);
  }

  async guardar(filas: Registro[]): Promise<number> {
    let escritas = 0;
    for (const fila of filas) {
      const existente = this.filas.get(fila.id);
      if (existente && fila.actualizado <= existente.actualizado) continue;
      this.filas.set(fila.id, structuredClone(fila));
      escritas++;
    }
    return escritas;
  }
}
