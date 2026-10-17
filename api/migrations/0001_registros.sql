-- Un solo tipo de fila para todo lo que se sincroniza: sesiones, mediciones y ajustes.
CREATE TABLE registros (
  id TEXT PRIMARY KEY,
  tipo TEXT NOT NULL,
  datos TEXT NOT NULL,
  actualizado INTEGER NOT NULL,
  borrado INTEGER NOT NULL DEFAULT 0
);
