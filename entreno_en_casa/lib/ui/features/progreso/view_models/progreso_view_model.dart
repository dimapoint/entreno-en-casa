import 'package:flutter/foundation.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/models/medicion.dart';
import '../../../../domain/models/registro_sesion.dart';
import '../../../../domain/plan/calendario.dart';
import '../../../../domain/plan/plan_casa.dart';
import 'campo_medicion.dart';

/// Cuánto cambió una medida contra el día 0.
class DiferenciaMedicion {
  const DiferenciaMedicion(this.campo, this.valor);

  final CampoMedicion campo;

  /// Ya redondeada a dos decimales para que no aparezcan restos como 2,6000000000000085.
  final double valor;

  bool get buenaSenal => campo.bajarEsMejor ? valor < 0 : valor > 0;

  String get texto =>
      valor == 0 ? 'Igual que el día 0' : '${textoConSigno(valor)} ${campo.unidad} vs. día 0';
}

/// Día 0 o semana 4, 8 o 13, con lo cargado hasta ahora (puede estar vacío).
class MomentoMedicion {
  const MomentoMedicion({
    required this.semana,
    required this.medicion,
    required this.diaCero,
    required this.pendiente,
  });

  final int semana;
  final Medicion? medicion;
  final Medicion? diaCero;

  /// Toca medir en este momento y todavía no se cargó nada.
  final bool pendiente;

  String get titulo => semana == 0 ? 'Día 0' : 'Semana $semana';

  num? valor(CampoMedicion campo) {
    final actual = medicion;
    return actual == null ? null : campo.valorEn(actual);
  }

  String textoDe(CampoMedicion campo) {
    final cargado = valor(campo);
    if (cargado == null) return '—';
    final nivel = campo == CampoMedicion.flexiones ? medicion?.flexionesNivel : null;
    return '${textoNumero(cargado)} ${campo.unidad}${nivel == null ? '' : ' · nivel $nivel'}';
  }

  /// Nula en el día 0, o si falta el dato en este momento o en el día 0.
  DiferenciaMedicion? diferencia(CampoMedicion campo) {
    final base = diaCero;
    final actual = valor(campo);
    if (semana == 0 || base == null || actual == null) return null;
    final inicial = campo.valorEn(base);
    if (inicial == null) return null;
    return DiferenciaMedicion(campo, ((actual - inicial) * 100).round() / 100);
  }
}

class ResumenHistorial {
  const ResumenHistorial({
    required this.sesiones,
    required this.sesionesEstaSemana,
    required this.rachaSemanas,
  });

  final int sesiones;
  final int sesionesEstaSemana;

  /// Semanas seguidas con al menos [ProgresoViewModel.sesionesDeFuerzaPorSemana] sesiones de fuerza.
  final int rachaSemanas;
}

class LineaEjercicio {
  const LineaEjercicio({required this.nombre, required this.nivel, required this.series});

  final String nombre;
  final String nivel;

  /// Como en el registro del PDF: "2 × 9, 8".
  final String series;
}

class ProgresoViewModel extends ChangeNotifier {
  ProgresoViewModel({required this._repositorio, DateTime Function()? ahora})
      : _ahora = ahora ?? DateTime.now {
    _leer();
    _repositorio.addListener(_alCambiarRepositorio);
  }

  static const sesionesDeFuerzaPorSemana = 3;

  final RepositorioEntrenamiento _repositorio;
  final DateTime Function() _ahora;

  // El repositorio arma estas listas parseando todo cada vez que se las pide.
  List<RegistroSesion> _sesiones = const [];
  Map<int, Medicion> _medicionesPorSemana = const {};

  void _leer() {
    _sesiones = _repositorio.sesiones;
    _medicionesPorSemana = {
      for (final medicion in _repositorio.mediciones) medicion.semana: medicion,
    };
  }

  void _alCambiarRepositorio() {
    _leer();
    notifyListeners();
  }

  // --- Mediciones ----------------------------------------------------------

  List<MomentoMedicion> get momentos {
    final queToca = _momentoQueTocaMedir();
    return [
      for (final semana in Calendario.semanasDeMedicion)
        MomentoMedicion(
          semana: semana,
          medicion: _medicionesPorSemana[semana],
          diaCero: _medicionesPorSemana[0],
          pendiente: semana == queToca && !_medicionesPorSemana.containsKey(semana),
        ),
    ];
  }

  /// Momento de medición de la semana del plan en curso, o nulo si no hay fecha de inicio,
  /// el plan todavía no empezó o esta semana no se mide.
  int? _momentoQueTocaMedir() {
    final inicio = _repositorio.fechaInicio;
    if (inicio == null) return null;
    final semanaDelPlan = Calendario.semanaDelPlan(inicio, _ahora());
    return semanaDelPlan == null ? null : Calendario.medicionDeLaSemana(semanaDelPlan);
  }

  List<String> get nivelesDeFlexiones => PlanCasa.ejercicioPorId('flexiones')?.niveles ?? const [];

  /// [textos] trae lo escrito en cada campo; los vacíos o inválidos quedan sin cargar.
  /// Devuelve falso, sin guardar nada, si no hay ningún dato.
  /// Al editar un momento ya cargado se conserva su fecha.
  Future<bool> guardarMedicion({
    required int semana,
    required Map<CampoMedicion, String> textos,
    int? nivelFlexiones,
  }) async {
    final valores = {
      for (final campo in CampoMedicion.values)
        campo: campo.validar(textos[campo]) == null ? campo.interpretar(textos[campo] ?? '') : null,
    };
    if (valores.values.every((valor) => valor == null)) return false;
    await _repositorio.guardarMedicion(Medicion(
      semana: semana,
      fecha: _medicionesPorSemana[semana]?.fecha ?? Calendario.soloFecha(_ahora()),
      pesoKg: valores[CampoMedicion.peso]?.toDouble(),
      cinturaCm: valores[CampoMedicion.cintura]?.toDouble(),
      flexiones: valores[CampoMedicion.flexiones]?.toInt(),
      flexionesNivel: nivelFlexiones,
      planchaSegundos: valores[CampoMedicion.plancha]?.toInt(),
      metros12Min: valores[CampoMedicion.prueba12Minutos]?.toInt(),
    ));
    return true;
  }

  // --- Historial -----------------------------------------------------------

  /// Más recientes primero.
  List<RegistroSesion> get sesiones => _sesiones;

  ResumenHistorial get resumen {
    final hoy = _ahora();
    final lunes = Calendario.lunesDe(hoy);
    return ResumenHistorial(
      sesiones: _sesiones.length,
      sesionesEstaSemana:
          _sesiones.where((sesion) => Calendario.lunesDe(sesion.fecha) == lunes).length,
      rachaSemanas: _rachaDeSemanas(lunes),
    );
  }

  int _rachaDeSemanas(DateTime lunesActual) {
    final fuerzaPorSemana = <DateTime, int>{};
    for (final sesion in _sesiones.where((sesion) => sesion.tipo.esFuerza)) {
      fuerzaPorSemana.update(Calendario.lunesDe(sesion.fecha), (cantidad) => cantidad + 1,
          ifAbsent: () => 1);
    }
    bool completa(DateTime lunes) => (fuerzaPorSemana[lunes] ?? 0) >= sesionesDeFuerzaPorSemana;

    var lunes = lunesActual;
    // La semana en curso todavía puede completarse, así que incompleta no corta la racha.
    if (!completa(lunes)) lunes = _lunesAnterior(lunes);
    var racha = 0;
    while (completa(lunes)) {
      racha++;
      lunes = _lunesAnterior(lunes);
    }
    return racha;
  }

  static DateTime _lunesAnterior(DateTime lunes) =>
      DateTime(lunes.year, lunes.month, lunes.day - 7);

  String resumenDeSesion(RegistroSesion sesion) {
    if (sesion.tipo.esFuerza) {
      final series = sesion.ejercicios
          .fold(0, (total, ejercicio) => total + ejercicio.repeticiones.length);
      return '${_conPlural(sesion.ejercicios.length, 'ejercicio')}, ${_conPlural(series, 'serie')}';
    }
    final minutos = sesion.duracionMinutos;
    return minutos == null ? 'Sin duración anotada' : '$minutos min';
  }

  static String _conPlural(int cantidad, String singular) =>
      cantidad == 1 ? '1 $singular' : '$cantidad ${singular}s';

  List<LineaEjercicio> ejerciciosDe(RegistroSesion sesion) =>
      [for (final hecho in sesion.ejercicios) _lineaDe(hecho)];

  LineaEjercicio _lineaDe(RegistroEjercicio hecho) {
    final ejercicio = PlanCasa.ejercicioPorId(hecho.ejercicioId);
    final niveles = ejercicio?.niveles ?? const <String>[];
    final nombreNivel =
        hecho.nivel >= 1 && hecho.nivel <= niveles.length ? niveles[hecho.nivel - 1] : null;
    final unidad = (ejercicio?.esTiempo ?? false) ? ' s' : '';
    return LineaEjercicio(
      nombre: ejercicio?.nombre ?? hecho.ejercicioId,
      nivel: nombreNivel == null ? 'Nivel ${hecho.nivel}' : 'Nivel ${hecho.nivel} · $nombreNivel',
      series: hecho.repeticiones.isEmpty
          ? 'Sin series'
          : '${hecho.repeticiones.length} × ${hecho.repeticiones.join(', ')}$unidad',
    );
  }

  Future<void> borrarSesion(String id) => _repositorio.borrarSesion(id);

  @override
  void dispose() {
    _repositorio.removeListener(_alCambiarRepositorio);
    super.dispose();
  }
}
