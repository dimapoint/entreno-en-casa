import 'dart:math' as matematica;

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/models/ejercicio.dart';
import '../../../../domain/models/registro_sesion.dart';
import '../../../../domain/models/semana_plan.dart';
import '../../../../domain/plan/calendario.dart';
import '../../../../domain/plan/plan_casa.dart';

enum EtapaHoy { sinFechaDeInicio, antesDeEmpezar, enCurso }

class DiaDeLaSemana {
  const DiaDeLaSemana({
    required this.fecha,
    required this.sesion,
    required this.registrada,
    required this.esHoy,
  });

  final DateTime fecha;

  /// Sesión planificada. Nula el domingo, que es descanso total.
  final TipoSesion? sesion;

  /// Hay al menos una sesión registrada ese día.
  final bool registrada;
  final bool esHoy;
}

/// Todo se calcula con el reloj en cada lectura: [refrescar] sirve para que la
/// pantalla se actualice cuando la app vuelve a primer plano después de medianoche.
/// Los datos de [EtapaHoy.antesDeEmpezar] y [EtapaHoy.enCurso] solo se pueden leer en esa etapa.
class HoyViewModel extends ChangeNotifier {
  HoyViewModel({required this._repositorio, DateTime Function()? ahora})
    : _ahora = ahora ?? DateTime.now {
    _repositorio.addListener(notifyListeners);
  }

  static const _diasDeFuerza = [
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  ];

  final RepositorioEntrenamiento _repositorio;
  final DateTime Function() _ahora;
  final Set<int> _preparativosHechos = {};

  DateTime get hoy => Calendario.soloFecha(_ahora());

  DateTime get proximoLunes => Calendario.proximoLunes(_ahora());

  EtapaHoy get etapa {
    final fechaInicio = _repositorio.fechaInicio;
    if (fechaInicio == null) return EtapaHoy.sinFechaDeInicio;
    return Calendario.semanaDelPlan(fechaInicio, _ahora()) == null
        ? EtapaHoy.antesDeEmpezar
        : EtapaHoy.enCurso;
  }

  Future<void> elegirFechaDeInicio(DateTime fecha) =>
      _repositorio.guardarFechaInicio(fecha);

  Future<void> arrancarElProximoLunes() => elegirFechaDeInicio(proximoLunes);

  void refrescar() => notifyListeners();

  // --- Antes de empezar ----------------------------------------------------

  DateTime get lunesDeInicio => Calendario.lunesDe(_repositorio.fechaInicio!);

  int get diasQueFaltan {
    final lunes = lunesDeInicio;
    return DateTime.utc(
      lunes.year,
      lunes.month,
      lunes.day,
    ).difference(DateTime.utc(hoy.year, hoy.month, hoy.day)).inDays;
  }

  String get cuentaRegresiva =>
      diasQueFaltan == 1 ? 'Falta 1 día' : 'Faltan $diasQueFaltan días';

  bool preparativoHecho(int indice) => _preparativosHechos.contains(indice);

  void alternarPreparativo(int indice) {
    if (!_preparativosHechos.add(indice)) _preparativosHechos.remove(indice);
    notifyListeners();
  }

  // --- En curso ------------------------------------------------------------

  /// Semana absoluta del plan: puede pasar de 13.
  int get semana =>
      Calendario.semanaDelPlan(_repositorio.fechaInicio!, _ahora())!;

  int get semanaEfectiva => Calendario.semanaEfectiva(semana);

  bool get cicloRepetido => semana > Calendario.totalSemanas;

  SemanaPlan get plan => Calendario.planDeLaSemana(semana);

  String get tituloDeLaSemana => cicloRepetido
      ? 'Semana $semana'
      : 'Semana $semana de ${Calendario.totalSemanas}';

  /// Momento de medición (0, 4, 8 o 13) de esta semana si toca y todavía no se cargó.
  int? get medicionPendiente {
    final momento = Calendario.medicionDeLaSemana(semana);
    if (momento == null) return null;
    final cargada = _repositorio.mediciones.any(
      (medicion) => medicion.semana == momento,
    );
    return cargada ? null : momento;
  }

  Rutina get rutinaDeHoy =>
      Calendario.rutinaSugerida(semana, _fuerzaHechaEstaSemana);

  /// Nula el domingo.
  TipoSesion? get sesionDeHoy =>
      Calendario.sesionDelDia(hoy, semana, rutinaDeHoy);

  bool get hizoSesionHoy => _sesionesDeEstaSemana.any(
    (sesion) => Calendario.soloFecha(sesion.fecha) == hoy,
  );

  /// Pasaron menos de 48 h desde la última fuerza y hoy toca fuerza.
  bool get avisarDescansoInsuficiente {
    if (sesionDeHoy?.esFuerza != true) return false;
    final ultimaFuerza = _repositorio.sesiones
        .where((sesion) => sesion.tipo.esFuerza)
        .firstOrNull;
    return Calendario.descansoInsuficiente(ultimaFuerza?.fecha, _ahora());
  }

  /// Sábado con minutos propios usa esos; el resto de los días, los del martes.
  int get minutosDeCardioSuave =>
      hoy.weekday == DateTime.saturday && plan.sabadoMinutos > 0
      ? plan.sabadoMinutos
      : plan.martesMinutos;

  String? get duracionDeHoy => switch (sesionDeHoy) {
    null => null,
    TipoSesion.fuerzaA || TipoSesion.fuerzaB => '45 a 55 min',
    TipoSesion.cardioSuave => '$minutosDeCardioSuave min',
    // 5 min suaves, vueltas de 4 min con 1 min de pausa entre ellas y 5 min para bajar.
    TipoSesion.intervalos => 'unos ${9 + 5 * plan.sabadoVueltas} min',
    TipoSesion.descansoActivo => '40 min',
  };

  String? get detalleDeHoy => switch (sesionDeHoy) {
    null => null,
    TipoSesion.fuerzaA || TipoSesion.fuerzaB =>
      '${PlanCasa.ejerciciosDe(rutinaDeHoy).length} ejercicios, con calentamiento y vuelta a la calma',
    TipoSesion.cardioSuave =>
      'Ritmo suave: tenés que poder hablar en frases de 5 a 8 palabras',
    TipoSesion.intervalos =>
      '5 min suaves, ${plan.sabadoVueltas} vueltas de 4 ejercicios (40 s fuerte y 20 s de pausa) y 5 min caminando para bajar',
    TipoSesion.descansoActivo => 'Caminata de 30 min más 10 min de movilidad',
  };

  /// De lunes a domingo de la semana actual.
  List<DiaDeLaSemana> get dias {
    final lunes = Calendario.lunesDe(hoy);
    final registrados = _sesionesDeEstaSemana
        .map((sesion) => Calendario.soloFecha(sesion.fecha))
        .toSet();
    return List.generate(7, (indice) {
      final fecha = DateTime(lunes.year, lunes.month, lunes.day + indice);
      final posicionDeFuerza = matematica.max(
        0,
        _diasDeFuerza.indexOf(fecha.weekday),
      );
      return DiaDeLaSemana(
        fecha: fecha,
        sesion: Calendario.sesionDelDia(
          fecha,
          semana,
          fecha == hoy
              ? rutinaDeHoy
              : Calendario.rutinaSugerida(semana, posicionDeFuerza),
        ),
        registrada: registrados.contains(fecha),
        esHoy: fecha == hoy,
      );
    });
  }

  int get _fuerzaHechaEstaSemana =>
      _sesionesDeEstaSemana.where((sesion) => sesion.tipo.esFuerza).length;

  List<RegistroSesion> get _sesionesDeEstaSemana {
    final lunes = Calendario.lunesDe(hoy);
    final lunesSiguiente = DateTime(lunes.year, lunes.month, lunes.day + 7);
    return _repositorio.sesiones.where((sesion) {
      final dia = Calendario.soloFecha(sesion.fecha);
      return !dia.isBefore(lunes) && dia.isBefore(lunesSiguiente);
    }).toList();
  }

  @override
  void dispose() {
    _repositorio.removeListener(notifyListeners);
    super.dispose();
  }
}
