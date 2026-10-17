/// Sobre genérico que viaja entre el dispositivo y el servidor.
/// Cada sesión, medición y el ajuste de fecha de inicio es un [Registro].
class Registro {
  const Registro({
    required this.id,
    required this.tipo,
    required this.datos,
    required this.actualizado,
    this.borrado = false,
    this.pendiente = false,
  });

  static const tipoSesion = 'sesion';
  static const tipoMedicion = 'medicion';
  static const tipoAjustes = 'ajustes';

  final String id;
  final String tipo;
  final Map<String, dynamic> datos;

  /// Milisegundos desde epoch. En un conflicto gana el más alto.
  final int actualizado;

  /// Los borrados se conservan como marca para que se propaguen a otros dispositivos.
  final bool borrado;

  /// Solo local: todavía no se subió al servidor.
  final bool pendiente;

  Registro copiarCon({bool? pendiente}) => Registro(
        id: id,
        tipo: tipo,
        datos: datos,
        actualizado: actualizado,
        borrado: borrado,
        pendiente: pendiente ?? this.pendiente,
      );

  /// Forma que se envía al servidor (sin el estado local).
  Map<String, dynamic> aJsonRemoto() => {
        'id': id,
        'tipo': tipo,
        'datos': datos,
        'actualizado': actualizado,
        'borrado': borrado,
      };

  Map<String, dynamic> aJsonLocal() => {...aJsonRemoto(), 'pendiente': pendiente};

  factory Registro.deJson(Map<String, dynamic> json) => Registro(
        id: json['id'] as String,
        tipo: json['tipo'] as String,
        datos: Map<String, dynamic>.from(json['datos'] as Map),
        actualizado: (json['actualizado'] as num).toInt(),
        borrado: json['borrado'] == true || json['borrado'] == 1,
        pendiente: json['pendiente'] == true,
      );
}
