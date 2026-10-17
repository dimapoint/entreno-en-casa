import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/registro.dart';

class ErrorApi implements Exception {
  const ErrorApi(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'ErrorApi: $mensaje';
}

/// Cliente del Worker: `GET` y `PUT` sobre `/api/registros` con el código como token.
class ServicioApi {
  ServicioApi({http.Client? cliente, String? urlBase})
    : _cliente = cliente ?? http.Client(),
      _urlBase = urlBase ?? const String.fromEnvironment('API_URL');

  final http.Client _cliente;
  final String _urlBase;

  static const _tiempoMaximo = Duration(seconds: 15);

  /// En web se usa el mismo origen que sirve la app. En Android hace falta `--dart-define=API_URL=...`.
  bool get disponible => _urlBase.isNotEmpty || kIsWeb;

  Uri get _direccion {
    if (_urlBase.isNotEmpty) return Uri.parse('$_urlBase/api/registros');
    if (kIsWeb) return Uri.base.resolve('/api/registros');
    throw const ErrorApi('Esta versión no tiene un servidor configurado.');
  }

  Map<String, String> _cabeceras(String codigo) => {
    'Authorization': 'Bearer $codigo',
    'Content-Type': 'application/json',
  };

  Future<List<Registro>> obtener(String codigo) async {
    final respuesta = await _pedir(
      () => _cliente.get(_direccion, headers: _cabeceras(codigo)),
    );
    try {
      final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
      return (cuerpo['registros'] as List)
          .map(
            (item) => Registro.deJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on Object {
      throw const ErrorApi('El servidor respondió algo que no se entiende.');
    }
  }

  Future<void> enviar(String codigo, List<Registro> registros) async {
    final cuerpo = jsonEncode({
      'registros': registros.map((registro) => registro.aJsonRemoto()).toList(),
    });
    await _pedir(
      () => _cliente.put(_direccion, headers: _cabeceras(codigo), body: cuerpo),
    );
  }

  Future<http.Response> _pedir(
    Future<http.Response> Function() peticion,
  ) async {
    final http.Response respuesta;
    try {
      respuesta = await peticion().timeout(_tiempoMaximo);
    } on ErrorApi {
      rethrow;
    } on TimeoutException {
      throw const ErrorApi('El servidor tardó demasiado en responder.');
    } on Object {
      throw const ErrorApi('No se pudo conectar. Revisá la conexión.');
    }
    if (respuesta.statusCode == 401) {
      throw const ErrorApi('El código de sincronización no es correcto.');
    }
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw ErrorApi(
        'El servidor respondió con error ${respuesta.statusCode}.',
      );
    }
    return respuesta;
  }
}
