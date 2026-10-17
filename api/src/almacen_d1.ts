import type { Almacen } from "./almacen";
import type { Registro, TipoRegistro } from "./validacion";

interface FilaRegistro {
  id: string;
  tipo: TipoRegistro;
  datos: string;
  actualizado: number;
  borrado: number;
}

// Último en escribir gana: la fila existente solo se pisa si la entrante es más nueva.
const GUARDAR = `INSERT INTO registros (id, tipo, datos, actualizado, borrado)
VALUES (?1, ?2, ?3, ?4, ?5)
ON CONFLICT(id) DO UPDATE SET
  tipo = excluded.tipo,
  datos = excluded.datos,
  actualizado = excluded.actualizado,
  borrado = excluded.borrado
WHERE excluded.actualizado > registros.actualizado`;

export class AlmacenD1 implements Almacen {
  private readonly base: D1Database;

  constructor(base: D1Database) {
    this.base = base;
  }

  // shortcut: devuelve todo sin paginar, alcanza para una sola persona; paginar si la tabla pasa de unos miles de filas.
  async listar(): Promise<Registro[]> {
    const { results } = await this.base
      .prepare("SELECT id, tipo, datos, actualizado, borrado FROM registros ORDER BY actualizado, id")
      .all<FilaRegistro>();
    return results.map((fila) => ({
      id: fila.id,
      tipo: fila.tipo,
      datos: JSON.parse(fila.datos) as Record<string, unknown>,
      actualizado: fila.actualizado,
      borrado: fila.borrado === 1,
    }));
  }

  async guardar(filas: Registro[]): Promise<number> {
    if (filas.length === 0) return 0;
    const sentencia = this.base.prepare(GUARDAR);
    const resultados = await this.base.batch(
      filas.map((fila) =>
        sentencia.bind(fila.id, fila.tipo, JSON.stringify(fila.datos), fila.actualizado, fila.borrado ? 1 : 0),
      ),
    );
    return resultados.reduce((total, resultado) => total + resultado.meta.changes, 0);
  }
}
