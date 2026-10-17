import type { Registro } from "./validacion";

export interface Almacen {
  listar(): Promise<Registro[]>;
  /** Guarda cada fila solo si es más nueva que la que ya existe. Devuelve cuántas se escribieron de verdad. */
  guardar(filas: Registro[]): Promise<number>;
}
