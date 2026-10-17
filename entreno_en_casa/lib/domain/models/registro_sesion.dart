enum TipoSesion {
  fuerzaA('Fuerza A'),
  fuerzaB('Fuerza B'),
  cardioSuave('Cardio suave'),
  intervalos('Intervalos'),
  descansoActivo('Descanso activo');

  const TipoSesion(this.etiqueta);

  final String etiqueta;

  bool get esFuerza => this == fuerzaA || this == fuerzaB;
}

/// Lo que hiciste en un ejercicio: una entrada por serie completada
/// (repeticiones, o segundos si es plancha).
class RegistroEjercicio {
  const RegistroEjercicio({
    required this.ejercicioId,
    required this.nivel,
    required this.repeticiones,
  });

  final String ejercicioId;

  /// Nivel de progresión usado, de 1 a 3.
  final int nivel;
  final List<int> repeticiones;

  Map<String, dynamic> aJson() => {
        'ejercicioId': ejercicioId,
        'nivel': nivel,
        'repeticiones': repeticiones,
      };

  factory RegistroEjercicio.deJson(Map<String, dynamic> json) => RegistroEjercicio(
        ejercicioId: json['ejercicioId'] as String,
        nivel: json['nivel'] as int,
        repeticiones: (json['repeticiones'] as List).map((valor) => valor as int).toList(),
      );
}

class RegistroSesion {
  const RegistroSesion({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.semana,
    this.ejercicios = const [],
    this.duracionMinutos,
    this.sensacion,
    this.diaFlojo = false,
    this.notas = '',
  });

  final String id;
  final DateTime fecha;
  final TipoSesion tipo;

  /// Semana absoluta del plan (puede pasar de 13).
  final int semana;
  final List<RegistroEjercicio> ejercicios;
  final int? duracionMinutos;

  /// "Cómo te sentiste", de 1 a 10.
  final int? sensacion;
  final bool diaFlojo;
  final String notas;

  Map<String, dynamic> aJson() => {
        'fecha': fecha.toIso8601String(),
        'tipo': tipo.name,
        'semana': semana,
        'ejercicios': ejercicios.map((ejercicio) => ejercicio.aJson()).toList(),
        'duracionMinutos': duracionMinutos,
        'sensacion': sensacion,
        'diaFlojo': diaFlojo,
        'notas': notas,
      };

  factory RegistroSesion.deJson(String id, Map<String, dynamic> json) => RegistroSesion(
        id: id,
        fecha: DateTime.parse(json['fecha'] as String),
        tipo: TipoSesion.values.byName(json['tipo'] as String),
        semana: json['semana'] as int,
        ejercicios: (json['ejercicios'] as List? ?? const [])
            .map((item) => RegistroEjercicio.deJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        duracionMinutos: json['duracionMinutos'] as int?,
        sensacion: json['sensacion'] as int?,
        diaFlojo: json['diaFlojo'] as bool? ?? false,
        notas: json['notas'] as String? ?? '',
      );
}
