/// Medición del día 0 o de las semanas 4, 8 y 13. Hay una sola por momento:
/// guardarla de nuevo reemplaza la anterior.
class Medicion {
  const Medicion({
    required this.semana,
    required this.fecha,
    this.pesoKg,
    this.cinturaCm,
    this.flexiones,
    this.flexionesNivel,
    this.planchaSegundos,
    this.metros12Min,
  });

  /// 0 para el día 0, o 4, 8 o 13.
  final int semana;
  final DateTime fecha;
  final double? pesoKg;
  final double? cinturaCm;
  final int? flexiones;
  final int? flexionesNivel;
  final int? planchaSegundos;
  final int? metros12Min;

  String get id => idPara(semana);

  static String idPara(int semana) => 'medicion-s$semana';

  Map<String, dynamic> aJson() => {
        'semana': semana,
        'fecha': fecha.toIso8601String(),
        'pesoKg': pesoKg,
        'cinturaCm': cinturaCm,
        'flexiones': flexiones,
        'flexionesNivel': flexionesNivel,
        'planchaSegundos': planchaSegundos,
        'metros12Min': metros12Min,
      };

  factory Medicion.deJson(Map<String, dynamic> json) => Medicion(
        semana: json['semana'] as int,
        fecha: DateTime.parse(json['fecha'] as String),
        pesoKg: (json['pesoKg'] as num?)?.toDouble(),
        cinturaCm: (json['cinturaCm'] as num?)?.toDouble(),
        flexiones: json['flexiones'] as int?,
        flexionesNivel: json['flexionesNivel'] as int?,
        planchaSegundos: json['planchaSegundos'] as int?,
        metros12Min: json['metros12Min'] as int?,
      );
}
