enum Rutina {
  a('A'),
  b('B');

  const Rutina(this.letra);

  final String letra;
}

/// Un bloque de la ficha técnica: "Posición", "Movimiento", "Errores comunes", etc.
class NotaTecnica {
  const NotaTecnica(this.titulo, this.texto);

  final String titulo;
  final String texto;
}

class Ejercicio {
  const Ejercicio({
    required this.id,
    required this.nombre,
    required this.rutina,
    required this.orden,
    required this.repeticiones,
    required this.repsMinimas,
    required this.repsMaximas,
    required this.descansoSegundos,
    required this.descansoTexto,
    required this.niveles,
    required this.notas,
    this.seriesTope = 3,
    this.cuartaSerieSemanas11y12 = false,
    this.esTiempo = false,
    this.porLado = false,
  });

  final String id;
  final String nombre;
  final Rutina rutina;

  /// Posición dentro de la rutina, de 1 a 6.
  final int orden;

  /// Texto del rango tal como figura en el plan, por ejemplo "8–12 por pierna".
  final String repeticiones;

  /// Piso y tope del rango. Para ejercicios de tiempo son segundos.
  final int repsMinimas;
  final int repsMaximas;

  /// Segundos que dura el temporizador de descanso (el tope si el plan da un rango).
  final int descansoSegundos;
  final String descansoTexto;

  /// Tres niveles de progresión, del más fácil al más difícil.
  final List<String> niveles;
  final List<NotaTecnica> notas;

  /// Máximo de series que el plan pide para este ejercicio en cualquier semana.
  final int seriesTope;

  /// Semanas 11 y 12 piden 4 series solo en sentadilla búlgara y flexiones.
  final bool cuartaSerieSemanas11y12;

  /// Plancha: se mide en segundos, no en repeticiones.
  final bool esTiempo;
  final bool porLado;

  String get unidad => esTiempo ? 's' : 'rep';
}
