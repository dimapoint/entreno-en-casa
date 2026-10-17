import '../../../../domain/models/medicion.dart';

/// Una de las cinco medidas que se cargan en cada momento de medición.
enum CampoMedicion {
  peso(
    etiqueta: 'Peso',
    unidad: 'kg',
    ayuda: 'El promedio de tus 3 pesadas',
    minimo: 30,
    maximo: 300,
    decimal: true,
    bajarEsMejor: true,
  ),
  cintura(
    etiqueta: 'Cintura',
    unidad: 'cm',
    ayuda: 'A la altura del ombligo, sin apretar',
    minimo: 40,
    maximo: 250,
    decimal: true,
    bajarEsMejor: true,
  ),
  flexiones(
    etiqueta: 'Flexiones',
    unidad: 'rep',
    ayuda: 'Máximo seguido con buena técnica',
    minimo: 0,
    maximo: 200,
  ),
  plancha(
    etiqueta: 'Plancha frontal',
    unidad: 's',
    ayuda: 'Máximo con buena postura',
    minimo: 1,
    maximo: 1800,
  ),
  prueba12Minutos(
    etiqueta: 'Prueba de 12 min',
    unidad: 'm',
    ayuda: 'Distancia caminando y trotando',
    minimo: 100,
    maximo: 6000,
  );

  const CampoMedicion({
    required this.etiqueta,
    required this.unidad,
    required this.ayuda,
    required this.minimo,
    required this.maximo,
    this.decimal = false,
    this.bajarEsMejor = false,
  });

  final String etiqueta;
  final String unidad;
  final String ayuda;
  final num minimo;
  final num maximo;

  /// Admite hasta dos decimales, con coma o punto. Si no, solo enteros.
  final bool decimal;

  /// En peso y cintura, que el número baje se lee como buena señal.
  final bool bajarEsMejor;

  static final _patronDecimal = RegExp(r'^\d+([.,]\d{1,2})?$');
  static final _patronEntero = RegExp(r'^\d+$');

  num? valorEn(Medicion medicion) => switch (this) {
    CampoMedicion.peso => medicion.pesoKg,
    CampoMedicion.cintura => medicion.cinturaCm,
    CampoMedicion.flexiones => medicion.flexiones,
    CampoMedicion.plancha => medicion.planchaSegundos,
    CampoMedicion.prueba12Minutos => medicion.metros12Min,
  };

  /// Número que escribió la persona, o nulo si el texto está vacío o no tiene formato válido.
  /// No mira el rango: eso lo hace [validar].
  num? interpretar(String texto) {
    final limpio = texto.trim();
    if (!(decimal ? _patronDecimal : _patronEntero).hasMatch(limpio)) {
      return null;
    }
    return num.tryParse(limpio.replaceAll(',', '.'));
  }

  /// Mensaje de error, o nulo si sirve. Vacío es válido: cada medida es opcional.
  String? validar(String? texto) {
    if (texto == null || texto.trim().isEmpty) return null;
    final valor = interpretar(texto);
    if (valor == null) {
      return decimal
          ? 'Escribí un número con coma o punto, por ejemplo 72,5'
          : 'Escribí un número entero';
    }
    if (valor < minimo || valor > maximo) {
      return 'Poné un valor entre ${textoNumero(minimo)} y ${textoNumero(maximo)}';
    }
    return null;
  }
}

/// Número con coma decimal y sin ceros de más: 72,5, 88 o 0,25.
String textoNumero(num valor) {
  final fijo = valor.toStringAsFixed(2);
  return fijo.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
}

/// "+4", "−2,6" o "0".
String textoConSigno(num valor) {
  if (valor == 0) return '0';
  return '${valor > 0 ? '+' : '−'}${textoNumero(valor.abs())}';
}
