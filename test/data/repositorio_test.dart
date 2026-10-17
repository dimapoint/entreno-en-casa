import 'dart:convert';

import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/medicion.dart';
import 'package:entreno_en_casa/domain/models/registro.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ServidorFalso {
  final Map<String, Map<String, dynamic>> guardados = {};
  int estado = 200;
  int llamadas = 0;

  http.Client get cliente => MockClient((peticion) async {
        llamadas++;
        if (estado != 200) return http.Response('error', estado);
        expect(peticion.headers['Authorization'], 'Bearer secreto');
        if (peticion.method == 'PUT') {
          final cuerpo = jsonDecode(peticion.body) as Map<String, dynamic>;
          for (final item in cuerpo['registros'] as List) {
            final registro = Map<String, dynamic>.from(item as Map);
            final previo = guardados[registro['id']];
            if (previo == null ||
                (registro['actualizado'] as int) > (previo['actualizado'] as int)) {
              guardados[registro['id'] as String] = registro;
            }
          }
          return http.Response(jsonEncode({'aceptados': guardados.length}), 200);
        }
        return http.Response(jsonEncode({'registros': guardados.values.toList()}), 200);
      });
}

Future<RepositorioEntrenamiento> _crear(
  _ServidorFalso servidor, {
  DateTime Function()? ahora,
}) async {
  final almacenamiento = ServicioAlmacenamiento(await SharedPreferences.getInstance());
  return RepositorioEntrenamiento(
    almacenamiento: almacenamiento,
    api: ServicioApi(cliente: servidor.cliente, urlBase: 'https://ejemplo.test'),
    ahora: ahora,
  );
}

/// Guardar lanza la sincronización sin esperarla: acá se espera a que termine.
Future<void> _esperarSync(RepositorioEntrenamiento repositorio) async {
  while (repositorio.estadoSync == EstadoSync.sincronizando) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

RegistroSesion _sesion(String id, DateTime fecha) => RegistroSesion(
      id: id,
      fecha: fecha,
      tipo: TipoSesion.fuerzaA,
      semana: 1,
      ejercicios: const [
        RegistroEjercicio(ejercicioId: 'flexiones', nivel: 1, repeticiones: [10, 9]),
      ],
      sensacion: 7,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin código funciona en modo local y no llama al servidor', () async {
    final servidor = _ServidorFalso();
    final repositorio = await _crear(servidor);
    await repositorio.iniciar();

    await repositorio.guardarSesion(_sesion('s1', DateTime(2026, 10, 19)));
    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19, 15));

    expect(repositorio.sesiones, hasLength(1));
    expect(repositorio.fechaInicio, DateTime(2026, 10, 19));
    expect(repositorio.estadoSync, EstadoSync.inactivo);
    expect(servidor.llamadas, 0);
    repositorio.dispose();
  });

  test('lo guardado sobrevive a reiniciar la app', () async {
    final servidor = _ServidorFalso();
    final primero = await _crear(servidor);
    await primero.iniciar();
    await primero.guardarSesion(_sesion('s1', DateTime(2026, 10, 19)));
    await primero.guardarMedicion(
      Medicion(semana: 0, fecha: DateTime(2026, 10, 19), pesoKg: 75.5),
    );
    primero.dispose();

    final segundo = await _crear(servidor);
    await segundo.iniciar();
    expect(segundo.sesiones.single.id, 's1');
    expect(segundo.sesiones.single.ejercicios.single.repeticiones, [10, 9]);
    expect(segundo.mediciones.single.pesoKg, 75.5);
    segundo.dispose();
  });

  test('sesiones más recientes primero y mediciones por momento', () async {
    final repositorio = await _crear(_ServidorFalso());
    await repositorio.iniciar();
    await repositorio.guardarSesion(_sesion('vieja', DateTime(2026, 10, 19)));
    await repositorio.guardarSesion(_sesion('nueva', DateTime(2026, 10, 21)));
    await repositorio.guardarMedicion(Medicion(semana: 8, fecha: DateTime(2026, 12, 14)));
    await repositorio.guardarMedicion(Medicion(semana: 0, fecha: DateTime(2026, 10, 19)));

    expect(repositorio.sesiones.map((sesion) => sesion.id), ['nueva', 'vieja']);
    expect(repositorio.mediciones.map((medicion) => medicion.semana), [0, 8]);
    repositorio.dispose();
  });

  test('guardar de nuevo la medición del mismo momento la reemplaza', () async {
    final repositorio = await _crear(_ServidorFalso());
    await repositorio.iniciar();
    await repositorio.guardarMedicion(
      Medicion(semana: 4, fecha: DateTime(2026, 11, 16), pesoKg: 74),
    );
    await repositorio.guardarMedicion(
      Medicion(semana: 4, fecha: DateTime(2026, 11, 16), pesoKg: 73),
    );
    expect(repositorio.mediciones.single.pesoKg, 73);
    repositorio.dispose();
  });

  test('con código sube lo pendiente y baja lo del servidor', () async {
    final servidor = _ServidorFalso();
    servidor.guardados['sesion-remota'] = Registro(
      id: 'sesion-remota',
      tipo: Registro.tipoSesion,
      datos: _sesion('sesion-remota', DateTime(2026, 10, 20)).aJson(),
      actualizado: 5,
    ).aJsonRemoto();

    final repositorio = await _crear(servidor);
    await repositorio.iniciar();
    await repositorio.guardarSesion(_sesion('sesion-local', DateTime(2026, 10, 19)));
    await repositorio.guardarCodigoSync('secreto');

    expect(repositorio.estadoSync, EstadoSync.ok);
    expect(servidor.guardados.keys, containsAll(['sesion-local', 'sesion-remota']));
    expect(repositorio.sesiones.map((sesion) => sesion.id), ['sesion-remota', 'sesion-local']);
    expect(repositorio.cantidadPendientes, 0);
    repositorio.dispose();
  });

  test('gana el registro más nuevo y los borrados se propagan', () async {
    final servidor = _ServidorFalso();
    var reloj = DateTime(2026, 10, 19, 10);
    final primero = await _crear(servidor, ahora: () => reloj);
    await primero.iniciar();
    await primero.guardarCodigoSync('secreto');
    await primero.guardarSesion(_sesion('s1', DateTime(2026, 10, 19)));
    await _esperarSync(primero);
    primero.dispose();

    SharedPreferences.setMockInitialValues({'codigo_sync': 'secreto'});
    reloj = DateTime(2026, 10, 19, 11);
    final segundo = await _crear(servidor, ahora: () => reloj);
    await segundo.iniciar();
    expect(segundo.sesiones, hasLength(1));
    await segundo.borrarSesion('s1');
    await _esperarSync(segundo);
    expect(segundo.sesiones, isEmpty);

    SharedPreferences.setMockInitialValues({'codigo_sync': 'secreto'});
    final tercero = await _crear(servidor, ahora: () => reloj);
    await tercero.iniciar();
    expect(tercero.sesiones, isEmpty);
    segundo.dispose();
    tercero.dispose();
  });

  test('si el servidor falla queda el error y lo pendiente se conserva', () async {
    final servidor = _ServidorFalso()..estado = 500;
    final repositorio = await _crear(servidor);
    await repositorio.iniciar();
    await repositorio.guardarCodigoSync('secreto');
    await repositorio.guardarSesion(_sesion('s1', DateTime(2026, 10, 19)));
    await _esperarSync(repositorio);

    expect(repositorio.estadoSync, EstadoSync.error);
    expect(repositorio.mensajeSync, isNotNull);
    expect(repositorio.cantidadPendientes, 1);

    servidor.estado = 200;
    await repositorio.sincronizar();
    expect(repositorio.estadoSync, EstadoSync.ok);
    expect(repositorio.cantidadPendientes, 0);
    repositorio.dispose();
  });

  test('un código incorrecto da un mensaje claro', () async {
    final servidor = _ServidorFalso()..estado = 401;
    final repositorio = await _crear(servidor);
    await repositorio.iniciar();
    await repositorio.guardarCodigoSync('secreto');
    expect(repositorio.estadoSync, EstadoSync.error);
    expect(repositorio.mensajeSync, contains('código'));
    repositorio.dispose();
  });
}
