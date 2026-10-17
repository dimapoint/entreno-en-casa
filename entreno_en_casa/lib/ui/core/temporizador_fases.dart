import 'dart:async';

import 'package:flutter/foundation.dart';

class FaseTemporizador {
  const FaseTemporizador({
    required this.titulo,
    required this.segundos,
    this.detalle,
    this.esDescanso = false,
  });

  final String titulo;
  final String? detalle;
  final int segundos;
  final bool esDescanso;
}

enum EstadoTemporizador { quieto, corriendo, pausado, terminado }

/// Temporizador por fases que se calcula con el reloj, no contando ticks:
/// si la app pasa a segundo plano, al volver muestra el tiempo real.
class ControladorFases extends ChangeNotifier {
  ControladorFases(
    this.fases, {
    DateTime Function()? ahora,
    this.alCambiarFase,
    this.alTerminar,
  })  : assert(fases.isNotEmpty),
        _ahora = ahora ?? DateTime.now;

  final List<FaseTemporizador> fases;
  final DateTime Function() _ahora;

  /// Se llama al arrancar y cada vez que empieza una fase nueva (por ejemplo para vibrar).
  final void Function(FaseTemporizador fase)? alCambiarFase;
  final VoidCallback? alTerminar;

  static const _intervaloDeRefresco = Duration(milliseconds: 250);

  Timer? _reloj;
  Duration _acumulado = Duration.zero;
  DateTime? _inicioTramo;
  EstadoTemporizador _estado = EstadoTemporizador.quieto;
  int _indiceNotificado = 0;

  EstadoTemporizador get estado => _estado;
  bool get corriendo => _estado == EstadoTemporizador.corriendo;

  int get duracionTotalSegundos => fases.fold(0, (total, fase) => total + fase.segundos);

  Duration get transcurrido {
    final tramo = _inicioTramo;
    final total = Duration(seconds: duracionTotalSegundos);
    final valor = tramo == null ? _acumulado : _acumulado + _ahora().difference(tramo);
    return valor > total ? total : valor;
  }

  int get indiceActual => _posicion(transcurrido).indice;
  FaseTemporizador get faseActual => fases[indiceActual];

  /// Segundos que faltan de la fase actual, redondeados hacia arriba.
  int get segundosRestantes => (_posicion(transcurrido).restanteMs / 1000).ceil();

  int get segundosRestantesTotal =>
      ((Duration(seconds: duracionTotalSegundos) - transcurrido).inMilliseconds / 1000).ceil();

  /// De 0 a 1.
  double get progresoTotal => duracionTotalSegundos == 0
      ? 1
      : transcurrido.inMilliseconds / (duracionTotalSegundos * 1000);

  ({int indice, int restanteMs}) _posicion(Duration tiempo) {
    var inicioFaseMs = 0;
    final tiempoMs = tiempo.inMilliseconds;
    for (var indice = 0; indice < fases.length; indice++) {
      final finFaseMs = inicioFaseMs + fases[indice].segundos * 1000;
      if (tiempoMs < finFaseMs) return (indice: indice, restanteMs: finFaseMs - tiempoMs);
      inicioFaseMs = finFaseMs;
    }
    return (indice: fases.length - 1, restanteMs: 0);
  }

  void iniciar() {
    if (_estado == EstadoTemporizador.corriendo) return;
    if (_estado == EstadoTemporizador.pausado) {
      reanudar();
      return;
    }
    _acumulado = Duration.zero;
    _indiceNotificado = 0;
    _arrancarReloj();
    alCambiarFase?.call(fases.first);
    notifyListeners();
  }

  void pausar() {
    if (_estado != EstadoTemporizador.corriendo) return;
    _acumulado = transcurrido;
    _frenarReloj();
    _estado = EstadoTemporizador.pausado;
    notifyListeners();
  }

  void reanudar() {
    if (_estado != EstadoTemporizador.pausado) return;
    _arrancarReloj();
    notifyListeners();
  }

  /// Salta al comienzo de la fase siguiente, o termina si ya es la última.
  void saltarFase() {
    if (_estado == EstadoTemporizador.quieto || _estado == EstadoTemporizador.terminado) return;
    var inicioSiguienteMs = 0;
    final indice = indiceActual;
    for (var posicion = 0; posicion <= indice; posicion++) {
      inicioSiguienteMs += fases[posicion].segundos * 1000;
    }
    _acumulado = Duration(milliseconds: inicioSiguienteMs);
    if (_inicioTramo != null) _inicioTramo = _ahora();
    actualizar();
  }

  void reiniciar() {
    _frenarReloj();
    _acumulado = Duration.zero;
    _indiceNotificado = 0;
    _estado = EstadoTemporizador.quieto;
    notifyListeners();
  }

  /// Recalcula con el reloj. Lo llama el temporizador interno y se puede llamar a mano.
  void actualizar() {
    if (_estado != EstadoTemporizador.corriendo && _estado != EstadoTemporizador.pausado) return;
    final total = Duration(seconds: duracionTotalSegundos);
    if (transcurrido >= total) {
      _acumulado = total;
      _frenarReloj();
      _estado = EstadoTemporizador.terminado;
      _indiceNotificado = fases.length - 1;
      notifyListeners();
      alTerminar?.call();
      return;
    }
    final indice = indiceActual;
    if (indice != _indiceNotificado) {
      _indiceNotificado = indice;
      alCambiarFase?.call(fases[indice]);
    }
    notifyListeners();
  }

  void _arrancarReloj() {
    _inicioTramo = _ahora();
    _estado = EstadoTemporizador.corriendo;
    _reloj?.cancel();
    _reloj = Timer.periodic(_intervaloDeRefresco, (_) => actualizar());
  }

  void _frenarReloj() {
    _reloj?.cancel();
    _reloj = null;
    _inicioTramo = null;
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
