enum FasePlan {
  base('Base'),
  construccion('Construcción'),
  intensificacion('Intensificación'),
  descarga('Descarga');

  const FasePlan(this.etiqueta);

  final String etiqueta;
}

enum TipoSabado { suave, intervalos, caminata }

class SemanaPlan {
  const SemanaPlan({
    required this.numero,
    required this.fase,
    required this.fuerzaTexto,
    required this.martesMinutos,
    required this.tipoSabado,
    this.sabadoMinutos = 0,
    this.sabadoVueltas = 0,
    this.hito,
  });

  final int numero;
  final FasePlan fase;
  final String fuerzaTexto;
  final int martesMinutos;
  final TipoSabado tipoSabado;

  /// Minutos del sábado cuando es cardio suave o caminata.
  final int sabadoMinutos;

  /// Vueltas del sábado cuando son intervalos.
  final int sabadoVueltas;
  final String? hito;

  String get sabadoTexto => switch (tipoSabado) {
    TipoSabado.suave => '$sabadoMinutos min suave',
    TipoSabado.intervalos => 'Intervalos, $sabadoVueltas vueltas',
    TipoSabado.caminata => 'Caminata de $sabadoMinutos min',
  };
}

/// Bloque de trote para quien arranca desde cero: [vueltas] veces
/// [trotarMin] trotando y [caminarMin] caminando. Con [caminarMin] en 0 es trote seguido.
class BloqueTrote {
  const BloqueTrote({
    required this.vueltas,
    required this.trotarMin,
    required this.caminarMin,
  });

  final int vueltas;
  final int trotarMin;
  final int caminarMin;

  String get texto => caminarMin == 0
      ? '$trotarMin min seguidos de trote suave'
      : '$vueltas vueltas de $trotarMin min trotando + $caminarMin min caminando';
}
