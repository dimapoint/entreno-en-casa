import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/models/ejercicio.dart';
import '../../../../domain/models/registro_sesion.dart';
import '../../../../domain/models/semana_plan.dart';
import '../../../../domain/plan/calendario.dart';
import '../../../../domain/plan/plan_casa.dart';
import '../../../core/temporizador_fases.dart';

/// Lo que hiciste en un ejercicio la última vez que lo entrenaste.
class UltimaVez {
  const UltimaVez({
    required this.fecha,
    required this.nivel,
    required this.repeticiones,
    required this.diaFlojo,
  });

  final DateTime fecha;
  final int nivel;
  final List<int> repeticiones;
  final bool diaFlojo;
}

class Sugerencia {
  const Sugerencia({required this.texto, this.nivelNuevo});

  final String texto;

  /// Nivel al que se ofrece subir. Nulo cuando ya estás en el último.
  final int? nivelNuevo;
}

/// Lista de pasos con casillas, para el calentamiento y la vuelta a la calma.
class ListaTildable {
  ListaTildable(this.items);

  final List<String> items;
  final Set<int> _hechos = {};

  bool estaHecho(int indice) => _hechos.contains(indice);

  int get cantidadHecha => _hechos.length;

  void alternar(int indice) {
    if (!_hechos.remove(indice)) _hechos.add(indice);
  }
}

class _Progreso {
  _Progreso({required this.nivel, required this.marca});

  int nivel;

  /// Valor del contador de la serie que sigue.
  int marca;
  final List<int> hechas = [];
}

class FuerzaViewModel extends ChangeNotifier {
  FuerzaViewModel({
    required this._repositorio,
    required this.rutina,
    required this.semana,
    DateTime Function()? ahora,
  })  : _ahora = ahora ?? DateTime.now,
        ejercicios = PlanCasa.ejerciciosDe(rutina),
        semanaEfectiva = Calendario.semanaEfectiva(semana),
        plan = Calendario.planDeLaSemana(semana),
        calentamiento = ListaTildable(PlanCasa.calentamiento),
        vueltaALaCalma = ListaTildable(PlanCasa.vueltaALaCalma) {
    _inicio = _ahora();
    _cargarAnteriores();
    for (final ejercicio in ejercicios) {
      final nivelAnterior = _anteriores[ejercicio.id]?.nivel ?? 1;
      _progresos[ejercicio.id] = _Progreso(
        nivel: nivelAnterior.clamp(1, ejercicio.niveles.length),
        marca: ejercicio.repsMinimas,
      );
    }
  }

  static const _segundosExtraDescanso = 15;
  static const _marcaMaxima = 999;
  static const _seriesMinimasParaProgresar = 2;

  final RepositorioEntrenamiento _repositorio;
  final DateTime Function() _ahora;
  final Map<String, _Progreso> _progresos = {};
  final Map<String, UltimaVez> _anteriores = {};

  final Rutina rutina;

  /// Semana absoluta del plan (puede pasar de 13).
  final int semana;
  final int semanaEfectiva;
  final List<Ejercicio> ejercicios;
  final SemanaPlan plan;
  final ListaTildable calentamiento;
  final ListaTildable vueltaALaCalma;
  late final DateTime _inicio;

  bool _diaFlojo = false;
  bool _consejoVisible = true;
  bool _guardada = false;
  bool _guardando = false;
  ControladorFases? _descanso;

  bool get esCicloRepetido => semana > Calendario.totalSemanas;

  // --- Día flojo -----------------------------------------------------------

  bool get diaFlojo => _diaFlojo;

  void cambiarDiaFlojo({required bool activo}) {
    _diaFlojo = activo;
    notifyListeners();
  }

  int seriesDe(Ejercicio ejercicio) =>
      Calendario.seriesPara(ejercicio, semanaEfectiva, diaFlojo: _diaFlojo);

  // --- Consejo -------------------------------------------------------------

  bool get consejoVisible => _consejoVisible;

  String get consejo {
    final parejas = switch (rutina) {
      Rutina.a => 'búlgara con flexiones, y remo con curl femoral',
      Rutina.b => 'zancadas con press militar, y remo invertido con puente',
    };
    return 'Para ahorrar unos 10 min, emparejá un ejercicio de piernas con uno de torso: '
        'una serie de cada uno, con 60 s entre medio. Probá $parejas.';
  }

  void descartarConsejo() {
    _consejoVisible = false;
    notifyListeners();
  }

  // --- Ejercicios ----------------------------------------------------------

  _Progreso _progresoDe(Ejercicio ejercicio) => _progresos[ejercicio.id]!;

  int nivelDe(Ejercicio ejercicio) => _progresoDe(ejercicio).nivel;

  /// El nivel vale para todo el ejercicio: se guarda el último que elegiste.
  void elegirNivel(Ejercicio ejercicio, int nivel) {
    if (nivel < 1 || nivel > ejercicio.niveles.length) return;
    _progresoDe(ejercicio).nivel = nivel;
    notifyListeners();
  }

  int marcaDe(Ejercicio ejercicio) => _progresoDe(ejercicio).marca;

  /// Las planchas suben de a 5 segundos para no tocar el botón 30 veces.
  int pasoDe(Ejercicio ejercicio) => ejercicio.esTiempo ? 5 : 1;

  void sumarMarca(Ejercicio ejercicio) => _moverMarca(ejercicio, pasoDe(ejercicio));

  void restarMarca(Ejercicio ejercicio) => _moverMarca(ejercicio, -pasoDe(ejercicio));

  void _moverMarca(Ejercicio ejercicio, int diferencia) {
    final progreso = _progresoDe(ejercicio);
    progreso.marca = (progreso.marca + diferencia).clamp(0, _marcaMaxima);
    notifyListeners();
  }

  List<int> repeticionesHechas(Ejercicio ejercicio) =>
      List.unmodifiable(_progresoDe(ejercicio).hechas);

  bool ejercicioCompleto(Ejercicio ejercicio) =>
      _progresoDe(ejercicio).hechas.length >= seriesDe(ejercicio);

  /// Da la serie por hecha con la marca actual y arranca el descanso.
  void completarSerie(Ejercicio ejercicio) {
    final progreso = _progresoDe(ejercicio);
    if (ejercicioCompleto(ejercicio) || progreso.marca <= 0) return;
    progreso.hechas.add(progreso.marca);
    _arrancarDescanso(ejercicio.descansoSegundos);
    notifyListeners();
  }

  void deshacerUltimaSerie(Ejercicio ejercicio) {
    final hechas = _progresoDe(ejercicio).hechas;
    if (hechas.isEmpty) return;
    hechas.removeLast();
    notifyListeners();
  }

  // --- Historial y progresión ----------------------------------------------

  UltimaVez? ultimaVez(Ejercicio ejercicio) => _anteriores[ejercicio.id];

  void _cargarAnteriores() {
    // Las sesiones vienen de la más reciente a la más vieja.
    for (final sesion in _repositorio.sesiones) {
      if (!sesion.tipo.esFuerza) continue;
      for (final registro in sesion.ejercicios) {
        _anteriores.putIfAbsent(
          registro.ejercicioId,
          () => UltimaVez(
            fecha: sesion.fecha,
            nivel: registro.nivel,
            repeticiones: registro.repeticiones,
            diaFlojo: sesion.diaFlojo,
          ),
        );
      }
    }
  }

  /// Sube de escalón si la última vez llegaste al tope del rango en todas las series.
  /// Los días flojos no cuentan, porque ese día no se busca subir repeticiones.
  Sugerencia? sugerenciaDe(Ejercicio ejercicio) {
    final anterior = _anteriores[ejercicio.id];
    if (anterior == null || anterior.diaFlojo) return null;
    final llegoAlTope = anterior.repeticiones.length >= _seriesMinimasParaProgresar &&
        anterior.repeticiones.every((repeticiones) => repeticiones >= ejercicio.repsMaximas);
    if (!llegoAlTope) return null;

    if (anterior.nivel < ejercicio.niveles.length) {
      if (nivelDe(ejercicio) > anterior.nivel) return null;
      final nivelNuevo = anterior.nivel + 1;
      return Sugerencia(
        texto: 'La última vez llegaste al tope en todas las series. '
            'Si la técnica fue prolija, pasá al nivel $nivelNuevo y volvé al piso del rango.',
        nivelNuevo: nivelNuevo,
      );
    }
    return Sugerencia(
      texto: ejercicio.esTiempo
          ? 'Llegaste al tope en el nivel más difícil. Sumá peso extra con la mochila.'
          : 'Llegaste al tope en el nivel más difícil. Probá bajar en 3–4 s con pausa de 1–2 s, '
              'o sumá peso extra.',
    );
  }

  // --- Descanso ------------------------------------------------------------

  ControladorFases? get descanso => _descanso;

  void _arrancarDescanso(int segundos) {
    _descanso?.dispose();
    _descanso = ControladorFases(
      [FaseTemporizador(titulo: 'Descanso', segundos: segundos, esDescanso: true)],
      ahora: _ahora,
      alTerminar: HapticFeedback.heavyImpact,
    )..iniciar();
  }

  void agregarTiempoDeDescanso() {
    final actual = _descanso;
    if (actual == null) return;
    _arrancarDescanso(actual.segundosRestantes + _segundosExtraDescanso);
    notifyListeners();
  }

  /// Saltar no vibra: la vibración avisa que se acabó el tiempo.
  void cerrarDescanso() {
    _descanso?.dispose();
    _descanso = null;
    notifyListeners();
  }

  // --- Calentamiento y vuelta a la calma -----------------------------------

  void alternarItem(ListaTildable lista, int indice) {
    lista.alternar(indice);
    notifyListeners();
  }

  // --- Guardado ------------------------------------------------------------

  bool get puedeGuardar => _progresos.values.any((progreso) => progreso.hechas.isNotEmpty);

  bool get haySinGuardar => !_guardada && puedeGuardar;

  /// Guarda la sesión con los ejercicios que tienen al menos una serie hecha.
  /// Devuelve falso si no hay nada para guardar o si ya se guardó.
  Future<bool> guardarSesion({required int sensacion, String notas = ''}) async {
    assert(sensacion >= 1 && sensacion <= 10);
    if (!puedeGuardar || _guardada || _guardando) return false;
    _guardando = true;
    try {
      await _repositorio.guardarSesion(
        RegistroSesion(
          id: _repositorio.idNuevoDeSesion(),
          fecha: _ahora(),
          tipo: rutina == Rutina.a ? TipoSesion.fuerzaA : TipoSesion.fuerzaB,
          semana: semana,
          ejercicios: [
            for (final ejercicio in ejercicios)
              if (_progresoDe(ejercicio).hechas.isNotEmpty)
                RegistroEjercicio(
                  ejercicioId: ejercicio.id,
                  nivel: nivelDe(ejercicio),
                  repeticiones: List.of(_progresoDe(ejercicio).hechas),
                ),
          ],
          duracionMinutos: _ahora().difference(_inicio).inMinutes,
          sensacion: sensacion,
          diaFlojo: _diaFlojo,
          notas: notas.trim(),
        ),
      );
      _guardada = true;
      return true;
    } finally {
      _guardando = false;
    }
  }

  @override
  void dispose() {
    _descanso?.dispose();
    super.dispose();
  }
}
