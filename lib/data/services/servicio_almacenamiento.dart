import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/registro.dart';

/// Guarda en el dispositivo los registros y los ajustes de sincronización.
class ServicioAlmacenamiento {
  ServicioAlmacenamiento(this._preferencias);

  static Future<ServicioAlmacenamiento> crear() async =>
      ServicioAlmacenamiento(await SharedPreferences.getInstance());

  static const _claveRegistros = 'registros_v1';
  static const _claveCodigo = 'codigo_sync';
  static const _claveUltimaSync = 'ultima_sync';

  final SharedPreferences _preferencias;

  List<Registro> leerRegistros() {
    final texto = _preferencias.getString(_claveRegistros);
    if (texto == null) return [];
    final List<dynamic> items;
    try {
      items = jsonDecode(texto) as List;
    } on Object {
      // Datos dañados por completo: se arranca vacío y el próximo sync los recupera del servidor.
      return [];
    }
    final registros = <Registro>[];
    for (final item in items) {
      try {
        registros.add(Registro.deJson(Map<String, dynamic>.from(item as Map)));
      } on Object {
        // Se descarta solo el registro dañado; el resto sigue.
      }
    }
    return registros;
  }

  Future<void> guardarRegistros(Iterable<Registro> registros) =>
      _preferencias.setString(
        _claveRegistros,
        jsonEncode(registros.map((registro) => registro.aJsonLocal()).toList()),
      );

  String get codigoSync => _preferencias.getString(_claveCodigo) ?? '';

  Future<void> guardarCodigoSync(String codigo) => codigo.isEmpty
      ? _preferencias.remove(_claveCodigo)
      : _preferencias.setString(_claveCodigo, codigo);

  DateTime? get ultimaSync {
    final texto = _preferencias.getString(_claveUltimaSync);
    return texto == null ? null : DateTime.tryParse(texto);
  }

  Future<void> guardarUltimaSync(DateTime fecha) =>
      _preferencias.setString(_claveUltimaSync, fecha.toIso8601String());
}
