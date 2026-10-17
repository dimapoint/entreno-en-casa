import 'dart:async';
import 'dart:math' as matematica;

import 'package:flutter/foundation.dart';

import '../../domain/models/medicion.dart';
import '../../domain/models/registro.dart';
import '../../domain/models/registro_sesion.dart';
import '../../domain/plan/calendario.dart';
import '../services/servicio_almacenamiento.dart';
import '../services/servicio_api.dart';

enum EstadoSync { inactivo, sincronizando, ok, error }

/// Fuente única de verdad: guarda todo primero en el dispositivo y lo sincroniza
/// con el servidor cuando hay código cargado. Sin código funciona en modo local.
class RepositorioEntrenamiento extends ChangeNotifier {
  RepositorioEntrenamiento({
    required this._almacenamiento,
    required this._api,
    DateTime Function()? ahora,
  }) : _ahora = ahora ?? DateTime.now;

  static const _idAjustes = 'ajustes';

  final ServicioAlmacenamiento _almacenamiento;
  final ServicioApi _api;
  final DateTime Function() _ahora;
  final Map<String, Registro> _registros = {};

  EstadoSync _estadoSync = EstadoSync.inactivo;
  String? _mensajeSync;
  DateTime? _ultimaSync;
  String _codigoSync = '';
  bool _cerrado = false;

  Future<void> iniciar() async {
    for (final registro in _almacenamiento.leerRegistros()) {
      _registros[registro.id] = registro;
    }
    _codigoSync = _almacenamiento.codigoSync;
    _ultimaSync = _almacenamiento.ultimaSync;
    _avisar();
    await sincronizar();
  }

  // --- Lectura -------------------------------------------------------------

  /// Más recientes primero.
  List<RegistroSesion> get sesiones => _vivos(Registro.tipoSesion)
      .map((registro) => RegistroSesion.deJson(registro.id, registro.datos))
      .toList()
    ..sort((izquierda, derecha) => derecha.fecha.compareTo(izquierda.fecha));

  /// Ordenadas por momento: día 0, 4, 8 y 13.
  List<Medicion> get mediciones => _vivos(Registro.tipoMedicion)
      .map((registro) => Medicion.deJson(registro.datos))
      .toList()
    ..sort((izquierda, derecha) => izquierda.semana.compareTo(derecha.semana));

  DateTime? get fechaInicio {
    final ajustes = _registros[_idAjustes];
    final texto = ajustes == null || ajustes.borrado ? null : ajustes.datos['fechaInicio'];
    return texto is String ? DateTime.tryParse(texto) : null;
  }

  // --- Escritura -----------------------------------------------------------

  Future<void> guardarSesion(RegistroSesion sesion) =>
      _guardar(Registro.tipoSesion, sesion.id, sesion.aJson());

  Future<void> borrarSesion(String id) => _borrar(id);

  Future<void> guardarMedicion(Medicion medicion) =>
      _guardar(Registro.tipoMedicion, medicion.id, medicion.aJson());

  Future<void> borrarMedicion(int semana) => _borrar(Medicion.idPara(semana));

  Future<void> guardarFechaInicio(DateTime fecha) {
    final dia = Calendario.soloFecha(fecha);
    final texto = '${dia.year.toString().padLeft(4, '0')}-'
        '${dia.month.toString().padLeft(2, '0')}-'
        '${dia.day.toString().padLeft(2, '0')}';
    return _guardar(Registro.tipoAjustes, _idAjustes, {'fechaInicio': texto});
  }

  /// Id nuevo para una sesión. Incluye un sufijo al azar para que dos
  /// dispositivos nunca generen el mismo.
  String idNuevoDeSesion() =>
      'sesion-${_ahora().millisecondsSinceEpoch}-${matematica.Random().nextInt(1 << 20)}';

  // --- Sincronización ------------------------------------------------------

  EstadoSync get estadoSync => _estadoSync;
  String? get mensajeSync => _mensajeSync;
  DateTime? get ultimaSync => _ultimaSync;
  String get codigoSync => _codigoSync;
  bool get sincronizacionDisponible => _api.disponible;
  int get cantidadPendientes => _registros.values.where((registro) => registro.pendiente).length;

  Future<void> guardarCodigoSync(String codigo) async {
    _codigoSync = codigo.trim();
    await _almacenamiento.guardarCodigoSync(_codigoSync);
    if (_codigoSync.isEmpty) {
      _estadoSync = EstadoSync.inactivo;
      _mensajeSync = null;
      _avisar();
      return;
    }
    await sincronizar();
  }

  Future<void> sincronizar() async {
    if (_codigoSync.isEmpty || _estadoSync == EstadoSync.sincronizando) return;
    _estadoSync = EstadoSync.sincronizando;
    _mensajeSync = null;
    _avisar();
    try {
      final enviados = _registros.values.where((registro) => registro.pendiente).toList();
      if (enviados.isNotEmpty) await _api.enviar(_codigoSync, enviados);
      for (final enviado in enviados) {
        final actual = _registros[enviado.id];
        // Si se editó mientras se enviaba, sigue pendiente.
        if (actual != null && actual.actualizado == enviado.actualizado) {
          _registros[enviado.id] = actual.copiarCon(pendiente: false);
        }
      }
      for (final remoto in await _api.obtener(_codigoSync)) {
        final local = _registros[remoto.id];
        if (local == null || remoto.actualizado > local.actualizado) {
          _registros[remoto.id] = remoto;
        }
      }
      _ultimaSync = _ahora();
      await _almacenamiento.guardarUltimaSync(_ultimaSync!);
      _estadoSync = EstadoSync.ok;
    } on ErrorApi catch (error) {
      _estadoSync = EstadoSync.error;
      _mensajeSync = error.mensaje;
    } on Object {
      _estadoSync = EstadoSync.error;
      _mensajeSync = 'No se pudo sincronizar.';
    }
    await _persistir();
    _avisar();
    if (_estadoSync == EstadoSync.ok && cantidadPendientes > 0) {
      unawaited(sincronizar());
    }
  }

  // --- Internos ------------------------------------------------------------

  Iterable<Registro> _vivos(String tipo) =>
      _registros.values.where((registro) => registro.tipo == tipo && !registro.borrado);

  Future<void> _guardar(String tipo, String id, Map<String, dynamic> datos) =>
      _escribir(Registro(
        id: id,
        tipo: tipo,
        datos: datos,
        actualizado: _marcaDeTiempo(id),
        pendiente: true,
      ));

  Future<void> _borrar(String id) {
    final actual = _registros[id];
    if (actual == null || actual.borrado) return Future.value();
    return _escribir(Registro(
      id: id,
      tipo: actual.tipo,
      datos: actual.datos,
      actualizado: _marcaDeTiempo(id),
      borrado: true,
      pendiente: true,
    ));
  }

  /// Siempre mayor que la marca anterior del mismo registro, aunque se edite dos veces en el mismo milisegundo.
  int _marcaDeTiempo(String id) =>
      matematica.max(_ahora().millisecondsSinceEpoch, (_registros[id]?.actualizado ?? 0) + 1);

  Future<void> _escribir(Registro registro) async {
    _registros[registro.id] = registro;
    await _persistir();
    _avisar();
    unawaited(sincronizar());
  }

  Future<void> _persistir() => _almacenamiento.guardarRegistros(_registros.values);

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
