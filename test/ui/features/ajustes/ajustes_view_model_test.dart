import 'dart:convert';

import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/ui/features/ajustes/view_models/ajustes_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<RepositorioEntrenamiento> _crear({String urlBase = 'https://ejemplo.test'}) async =>
    RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(await SharedPreferences.getInstance()),
      api: ServicioApi(
        cliente: MockClient(
          (_) async => http.Response(jsonEncode({'registros': <Object>[]}), 200),
        ),
        urlBase: urlBase,
      ),
      ahora: () => DateTime(2026, 10, 17, 14, 5),
    );

void main() {
  late RepositorioEntrenamiento repositorio;
  late AjustesViewModel viewModel;

  Future<void> preparar({String urlBase = 'https://ejemplo.test'}) async {
    repositorio = await _crear(urlBase: urlBase);
    viewModel = AjustesViewModel(repositorio: repositorio);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() {
    viewModel.dispose();
    repositorio.dispose();
  });

  test('guardar el código lo limpia, lo conserva y sincroniza', () async {
    await preparar();
    expect(viewModel.hayCodigo, isFalse);
    expect(viewModel.textoDeEstado, 'Sin código: todo queda solo en este dispositivo');
    expect(viewModel.puedeSincronizar, isFalse);

    await viewModel.guardarCodigo('  secreto ');

    expect(viewModel.codigoGuardado, 'secreto');
    expect(viewModel.hayCodigo, isTrue);
    expect(viewModel.estadoSync, EstadoSync.ok);
    expect(viewModel.textoDeEstado, 'Todo sincronizado');
    expect(viewModel.textoDeUltimaSync, 'Última sincronización: sábado 17 de octubre a las 14:05');
    expect(viewModel.puedeSincronizar, isTrue);
  });

  test('quitar el código vuelve al modo local', () async {
    await preparar();
    await viewModel.guardarCodigo('secreto');

    await viewModel.quitarCodigo();

    expect(viewModel.hayCodigo, isFalse);
    expect(repositorio.codigoSync, isEmpty);
    expect(viewModel.estadoSync, EstadoSync.inactivo);
    expect(viewModel.puedeSincronizar, isFalse);
  });

  test('sin sincronizar avisa que todavía no sincronizaste', () async {
    await preparar();

    expect(viewModel.textoDeUltimaSync, 'Todavía no sincronizaste');
  });

  test('sincronizar ahora actualiza la última sincronización', () async {
    await preparar();
    await viewModel.guardarCodigo('secreto');

    await viewModel.sincronizarAhora();

    expect(viewModel.estadoSync, EstadoSync.ok);
    expect(repositorio.ultimaSync, DateTime(2026, 10, 17, 14, 5));
  });

  test('guarda la fecha de inicio y arranca la semana 1 el lunes de esa semana', () async {
    await preparar();
    expect(viewModel.fechaInicio, isNull);
    expect(viewModel.lunesDeInicio, isNull);

    await viewModel.guardarFechaDeInicio(DateTime(2026, 10, 21));

    expect(viewModel.fechaInicio, DateTime(2026, 10, 21));
    expect(viewModel.lunesDeInicio, DateTime(2026, 10, 19));
  });

  test('cuenta los cambios pendientes de subir', () async {
    await preparar();
    expect(viewModel.textoDePendientes, 'Nada pendiente de subir');

    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    expect(viewModel.textoDePendientes, '1 cambio pendiente de subir');

    await repositorio.guardarSesion(
      RegistroSesion(
        id: 's1',
        fecha: DateTime(2026, 10, 19),
        tipo: TipoSesion.fuerzaA,
        semana: 1,
      ),
    );
    expect(viewModel.textoDePendientes, '2 cambios pendientes de subir');
  });

  test('sin servidor configurado lo informa y no deja sincronizar', () async {
    await preparar(urlBase: '');
    expect(viewModel.sincronizacionDisponible, isFalse);

    await viewModel.guardarCodigo('secreto');

    expect(viewModel.estadoSync, EstadoSync.error);
    expect(viewModel.textoDeEstado, 'No se pudo sincronizar');
    expect(viewModel.mensajeSync, 'Esta versión no tiene un servidor configurado.');
    expect(viewModel.puedeSincronizar, isFalse);
  });

  test('avisa cuando cambia el repositorio', () async {
    await preparar();
    var avisos = 0;
    viewModel.addListener(() => avisos++);

    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));

    expect(avisos, greaterThan(0));
  });
}
