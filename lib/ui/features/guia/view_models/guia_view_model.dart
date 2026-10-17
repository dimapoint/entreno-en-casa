import 'package:flutter/foundation.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/plan/calendario.dart';
import '../../../../domain/plan/guia.dart';

const _conTilde = 'áéíóúü';
const _sinTilde = 'aeiouu';

/// Minúsculas y sin tildes en las vocales. La eñe se conserva: es otra letra.
String _normalizar(String texto) => texto.toLowerCase().replaceAllMapped(
  RegExp('[$_conTilde]'),
  (coincidencia) => _sinTilde[_conTilde.indexOf(coincidencia[0]!)],
);

/// Filtra las secciones de la guía y dice qué semana del plan está en curso.
class GuiaViewModel extends ChangeNotifier {
  GuiaViewModel({required this._repositorio, DateTime Function()? ahora})
    : _ahora = ahora ?? DateTime.now {
    _repositorio.addListener(notifyListeners);
  }

  final RepositorioEntrenamiento _repositorio;
  final DateTime Function() _ahora;
  final _textos = {
    for (final seccion in Guia.secciones)
      seccion: _normalizar(seccion.textoPlano),
  };

  String _consulta = '';
  List<String> _terminos = const [];

  String get consulta => _consulta;

  bool get buscando => _terminos.isNotEmpty;

  /// Una sección aparece si contiene todas las palabras de la búsqueda.
  List<SeccionGuia> get seccionesVisibles => [
    for (final seccion in Guia.secciones)
      if (_terminos.every(_textos[seccion]!.contains)) seccion,
  ];

  /// Semana absoluta del plan (puede pasar de 13). Nula sin fecha de inicio o si todavía no empezó.
  int? get semanaActual {
    final inicio = _repositorio.fechaInicio;
    return inicio == null ? null : Calendario.semanaDelPlan(inicio, _ahora());
  }

  /// Semana de la tabla del plan (1 a 13) que corresponde a la actual.
  int? get semanaResaltada {
    final actual = semanaActual;
    return actual == null ? null : Calendario.semanaEfectiva(actual);
  }

  void buscar(String texto) {
    if (texto == _consulta) return;
    _consulta = texto;
    _terminos = _normalizar(texto)
        .split(' ')
        .where((termino) => termino.isNotEmpty)
        .toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _repositorio.removeListener(notifyListeners);
    super.dispose();
  }
}
