import 'dart:math' as matematica;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/models/registro_sesion.dart';
import '../../../../domain/models/semana_plan.dart';
import '../../../../domain/plan/calendario.dart';
import '../../../../domain/plan/plan_casa.dart';
import '../../../core/formato.dart';
import '../../../core/temporizador_fases.dart';

const _intensidadSuave =
    'Esfuerzo de 4 a 5 sobre 10. Hablás en frases de 5 a 8 palabras. Pulso de 115 a 135 lpm.';
const _intensidadFuerte = 'Esfuerzo 8 sobre 10. Solo palabras sueltas. Pulso de 160 lpm o más.';

const _minutosEntradaEnCalor = 5;
const _segundosFuerte = 40;
const _segundosPausa = 20;
const _segundosEntreVueltas = 60;
const _minutosBajada = 5;

/// Con los intervalos fuera de su semana (antes de la 5) el plan no da vueltas: se usan estas.
const _vueltasFueraDelPlan = 3;

const _minutosCaminataDescansoActivo = 30;
const _minutosPorRondaDeMovilidad = 5;
const _rondasDeMovilidad = 2;

typedef _EjercicioDeIntervalos = ({String nombre, String? pista});

const _ejerciciosDeIntervalos = <_EjercicioDeIntervalos>[
  (nombre: 'soga rápida o trote rápido en el lugar', pista: null),
  (
    nombre: 'escaladores',
    pista: 'En posición de flexión, llevás las rodillas al pecho alternando, rápido.',
  ),
  (nombre: 'sentadillas rápidas sin peso', pista: null),
  (nombre: 'rodillas arriba trotando en el lugar', pista: null),
];

final _nombresDeEjerciciosDeIntervalos =
    _ejerciciosDeIntervalos.map((ejercicio) => ejercicio.nombre).join(', ');

typedef OpcionDeCardio = ({String titulo, String texto});

const _opcionesDeCardioSuave = <OpcionDeCardio>[
  (
    titulo: 'Caminata rápida o trote por el barrio',
    texto: 'La más fácil de sostener y la que más rinde por minuto.',
  ),
  (
    titulo: 'Soga',
    texto: 'Bloques de 2 a 3 min con 1 min de pausa caminando. Saltá bajito, sobre la punta de los pies.',
  ),
  (
    titulo: 'Escalera o escalón',
    texto: 'Subir y bajar a ritmo constante, cambiando la pierna que sube primero cada minuto.',
  ),
  (
    titulo: 'Mezclas',
    texto: 'Por ejemplo, 10 min de soga en bloques + 20 min de caminata.',
  ),
];

class CardioViewModel extends ChangeNotifier {
  CardioViewModel({
    required this._repositorio,
    required this.tipo,
    required this.semana,
    this._minutos,
    DateTime Function()? ahora,
  })  : assert(!tipo.esFuerza, 'La fuerza tiene su propia pantalla'),
        assert(semana >= 1),
        _ahora = ahora ?? DateTime.now {
    _controlador = _crearControlador();
  }

  final RepositorioEntrenamiento _repositorio;
  final DateTime Function() _ahora;
  final int? _minutos;

  final TipoSesion tipo;

  /// Semana absoluta del plan (puede pasar de 13).
  final int semana;

  late ControladorFases _controlador;
  bool _desdeCero = false;
  bool _guardando = false;

  late final int _minutosDeCardioSuave = _minutos ?? _minutosDeHoy();

  /// El temporizador vigente. Cambia de instancia al activar o desactivar "desde cero",
  /// pero este modelo avisa en cada cambio de cualquiera de los dos.
  ControladorFases get controlador => _controlador;

  bool get desdeCero => _desdeCero;

  /// Solo el cardio suave tiene la opción de arrancar a trotar desde cero.
  bool get permiteDesdeCero => tipo == TipoSesion.cardioSuave;

  /// Hay algo hecho que se puede guardar. Con 0 minutos transcurridos no hay nada.
  bool get puedeGuardar => _controlador.transcurrido > Duration.zero;

  int get duracionRealMinutos =>
      matematica.max(1, (_controlador.transcurrido.inMilliseconds / 60000).round());

  /// Los intervalos fuera de su semana se dejan hacer, pero se avisa.
  String? get aviso => tipo == TipoSesion.intervalos && _plan.tipoSabado != TipoSabado.intervalos
      ? 'El plan arranca los intervalos en la semana 5. Si querés hacerlos igual, vas con '
          '$_vueltasFueraDelPlan vueltas.'
      : null;

  List<OpcionDeCardio> get opciones =>
      permiteDesdeCero && !_desdeCero ? _opcionesDeCardioSuave : const [];

  /// Los pasos de la movilidad del descanso activo.
  List<String> get pasosDeMovilidad =>
      tipo == TipoSesion.descansoActivo ? PlanCasa.movilidad : const [];

  /// Resumen de la sesión para mostrar antes de arrancar.
  List<String> get estructura => switch (tipo) {
        TipoSesion.cardioSuave => [
            _desdeCero
                ? PlanCasa.troteDesdeCero(_semanaEfectiva).texto
                : '$_minutosDeCardioSuave min de cardio suave',
            _intensidadSuave,
          ],
        TipoSesion.intervalos => [
            '$_minutosEntradaEnCalor min suaves: caminata o trote en el lugar',
            '$_vueltas vueltas de ${_ejerciciosDeIntervalos.length} ejercicios, '
                '$_segundosFuerte s fuerte y $_segundosPausa s de pausa cada uno',
            'En cada vuelta: $_nombresDeEjerciciosDeIntervalos',
            '${_segundosEntreVueltas ~/ 60} min caminando entre vueltas',
            '$_minutosBajada min caminando para bajar',
            _intensidadFuerte,
          ],
        TipoSesion.descansoActivo => [
            '$_minutosCaminataDescansoActivo min de caminata tranquila',
            '${_minutosPorRondaDeMovilidad * _rondasDeMovilidad} min de movilidad, '
                '$_rondasDeMovilidad rondas de $_minutosPorRondaDeMovilidad min',
          ],
        TipoSesion.fuerzaA || TipoSesion.fuerzaB => throw StateError('No es una sesión de cardio'),
      };

  int get _semanaEfectiva => Calendario.semanaEfectiva(semana);

  SemanaPlan get _plan => PlanCasa.semana(_semanaEfectiva);

  int get _vueltas =>
      _plan.tipoSabado == TipoSabado.intervalos ? _plan.sabadoVueltas : _vueltasFueraDelPlan;

  int _minutosDeHoy() => _ahora().weekday == DateTime.saturday && _plan.sabadoMinutos > 0
      ? _plan.sabadoMinutos
      : _plan.martesMinutos;

  /// Solo se puede cambiar antes de arrancar: después, la sesión armada ya está en marcha.
  void cambiarDesdeCero(bool valor) {
    final quieto = _controlador.estado == EstadoTemporizador.quieto;
    if (!permiteDesdeCero || !quieto || valor == _desdeCero) return;
    _desdeCero = valor;
    _controlador.dispose();
    _controlador = _crearControlador();
    notifyListeners();
  }

  /// Devuelve falso si no había nada para guardar o ya se está guardando.
  Future<bool> guardar({required int sensacion, String notas = ''}) async {
    assert(sensacion >= 1 && sensacion <= 10);
    if (!puedeGuardar || _guardando) return false;
    _guardando = true;
    try {
      await _repositorio.guardarSesion(RegistroSesion(
        id: _repositorio.idNuevoDeSesion(),
        fecha: _ahora(),
        tipo: tipo,
        semana: semana,
        duracionMinutos: duracionRealMinutos,
        sensacion: sensacion,
        notas: notas.trim(),
      ));
      return true;
    } finally {
      _guardando = false;
    }
  }

  ControladorFases _crearControlador() => ControladorFases(
        _armarFases(),
        ahora: _ahora,
        alCambiarFase: (_) => HapticFeedback.heavyImpact(),
        alTerminar: HapticFeedback.heavyImpact,
      )..addListener(notifyListeners);

  List<FaseTemporizador> _armarFases() => switch (tipo) {
        TipoSesion.cardioSuave => _fasesDeCardioSuave(),
        TipoSesion.intervalos => _fasesDeIntervalos(),
        TipoSesion.descansoActivo => _fasesDeDescansoActivo(),
        TipoSesion.fuerzaA || TipoSesion.fuerzaB => throw StateError('No es una sesión de cardio'),
      };

  List<FaseTemporizador> _fasesDeCardioSuave() {
    if (!_desdeCero) {
      return [
        FaseTemporizador(
          titulo: 'Cardio suave',
          segundos: _minutosDeCardioSuave * 60,
          detalle: _intensidadSuave,
        ),
      ];
    }
    final bloque = PlanCasa.troteDesdeCero(_semanaEfectiva);
    if (bloque.caminarMin == 0) {
      return [
        FaseTemporizador(
          titulo: 'Trote suave seguido',
          segundos: bloque.trotarMin * 60,
          detalle: _intensidadSuave,
        ),
      ];
    }
    return [
      for (var vuelta = 1; vuelta <= bloque.vueltas; vuelta++) ...[
        FaseTemporizador(
          titulo: 'Trotá',
          segundos: bloque.trotarMin * 60,
          detalle: 'Vuelta $vuelta de ${bloque.vueltas}. $_intensidadSuave',
        ),
        FaseTemporizador(
          titulo: 'Caminá',
          segundos: bloque.caminarMin * 60,
          detalle: 'Vuelta $vuelta de ${bloque.vueltas}. Recuperá el aire caminando.',
          esDescanso: true,
        ),
      ],
    ];
  }

  List<FaseTemporizador> _fasesDeIntervalos() {
    final vueltas = _vueltas;
    return [
      const FaseTemporizador(
        titulo: 'Entrada en calor',
        segundos: _minutosEntradaEnCalor * 60,
        detalle: 'Caminata o trote en el lugar, bien suave.',
      ),
      for (var vuelta = 1; vuelta <= vueltas; vuelta++) ...[
        for (var indice = 0; indice < _ejerciciosDeIntervalos.length; indice++) ...[
          FaseTemporizador(
            titulo: conPrimeraMayuscula(_ejerciciosDeIntervalos[indice].nombre),
            segundos: _segundosFuerte,
            detalle: [
              'Vuelta $vuelta de $vueltas.',
              ?_ejerciciosDeIntervalos[indice].pista,
              _intensidadFuerte,
            ].join(' '),
          ),
          FaseTemporizador(
            titulo: 'Pausa',
            segundos: _segundosPausa,
            detalle: 'Sigue: ${_queSigueDespuesDeLaPausa(vuelta, vueltas, indice)}.',
            esDescanso: true,
          ),
        ],
        if (vuelta < vueltas)
          FaseTemporizador(
            titulo: 'Caminata',
            segundos: _segundosEntreVueltas,
            detalle: 'Recuperá antes de la vuelta ${vuelta + 1} de $vueltas.',
            esDescanso: true,
          ),
      ],
      const FaseTemporizador(
        titulo: 'Bajá caminando',
        segundos: _minutosBajada * 60,
        detalle: 'Caminá para bajar las pulsaciones.',
        esDescanso: true,
      ),
    ];
  }

  String _queSigueDespuesDeLaPausa(int vuelta, int vueltas, int indiceDeEjercicio) {
    if (indiceDeEjercicio < _ejerciciosDeIntervalos.length - 1) {
      return _ejerciciosDeIntervalos[indiceDeEjercicio + 1].nombre;
    }
    return vuelta < vueltas ? 'caminata entre vueltas' : 'caminata para bajar';
  }

  List<FaseTemporizador> _fasesDeDescansoActivo() => [
        const FaseTemporizador(
          titulo: 'Caminata',
          segundos: _minutosCaminataDescansoActivo * 60,
          detalle: 'Paso tranquilo, sin apuro. Hoy se recupera.',
        ),
        for (var ronda = 1; ronda <= _rondasDeMovilidad; ronda++)
          FaseTemporizador(
            titulo: 'Movilidad, ronda $ronda de $_rondasDeMovilidad',
            segundos: _minutosPorRondaDeMovilidad * 60,
            detalle: PlanCasa.movilidad.join('\n'),
          ),
      ];

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }
}
