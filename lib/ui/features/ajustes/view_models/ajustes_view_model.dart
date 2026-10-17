import 'package:flutter/foundation.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/plan/calendario.dart';
import '../../../core/formato.dart';

class AjustesViewModel extends ChangeNotifier {
  AjustesViewModel({required this._repositorio}) {
    _repositorio.addListener(notifyListeners);
  }

  final RepositorioEntrenamiento _repositorio;

  // --- Fecha de inicio -----------------------------------------------------

  DateTime? get fechaInicio => _repositorio.fechaInicio;

  /// Lunes de la semana 1: el plan siempre arranca un lunes.
  DateTime? get lunesDeInicio {
    final fecha = fechaInicio;
    return fecha == null ? null : Calendario.lunesDe(fecha);
  }

  Future<void> guardarFechaDeInicio(DateTime fecha) => _repositorio.guardarFechaInicio(fecha);

  // --- Sincronización ------------------------------------------------------

  String get codigoGuardado => _repositorio.codigoSync;

  bool get hayCodigo => codigoGuardado.isNotEmpty;

  bool get sincronizacionDisponible => _repositorio.sincronizacionDisponible;

  EstadoSync get estadoSync => _repositorio.estadoSync;

  /// Solo tiene valor si la última sincronización falló.
  String? get mensajeSync => _repositorio.mensajeSync;

  bool get puedeSincronizar =>
      sincronizacionDisponible && hayCodigo && estadoSync != EstadoSync.sincronizando;

  String get textoDeEstado => switch (estadoSync) {
        EstadoSync.inactivo =>
          hayCodigo ? 'Listo para sincronizar' : 'Sin código: todo queda solo en este dispositivo',
        EstadoSync.sincronizando => 'Sincronizando...',
        EstadoSync.ok => 'Todo sincronizado',
        EstadoSync.error => 'No se pudo sincronizar',
      };

  String get textoDePendientes => switch (_repositorio.cantidadPendientes) {
        0 => 'Nada pendiente de subir',
        1 => '1 cambio pendiente de subir',
        final cantidad => '$cantidad cambios pendientes de subir',
      };

  String get textoDeUltimaSync {
    final fecha = _repositorio.ultimaSync;
    if (fecha == null) return 'Todavía no sincronizaste';
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');
    return 'Última sincronización: ${fechaLarga(fecha)} a las $hora:$minutos';
  }

  /// Un código vacío equivale a quitarlo.
  Future<void> guardarCodigo(String codigo) => _repositorio.guardarCodigoSync(codigo);

  Future<void> quitarCodigo() => _repositorio.guardarCodigoSync('');

  Future<void> sincronizarAhora() => _repositorio.sincronizar();

  @override
  void dispose() {
    _repositorio.removeListener(notifyListeners);
    super.dispose();
  }
}
