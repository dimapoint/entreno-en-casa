import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/medicion.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/ui/features/progreso/view_models/campo_medicion.dart';
import 'package:entreno_en_casa/ui/features/progreso/view_models/progreso_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime reloj;
  late RepositorioEntrenamiento repositorio;
  late ProgresoViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    reloj = DateTime(2026, 10, 19, 9);
    repositorio = RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(
        await SharedPreferences.getInstance(),
      ),
      api: ServicioApi(
        cliente: MockClient((_) async => http.Response('', 500)),
      ),
      ahora: () => reloj,
    );
    await repositorio.iniciar();
    viewModel = ProgresoViewModel(repositorio: repositorio, ahora: () => reloj);
  });

  tearDown(() {
    viewModel.dispose();
    repositorio.dispose();
  });

  MomentoMedicion momento(int semana) =>
      viewModel.momentos.singleWhere((candidato) => candidato.semana == semana);

  RegistroSesion sesion(
    String id,
    DateTime fecha, {
    TipoSesion tipo = TipoSesion.fuerzaA,
  }) => RegistroSesion(id: id, fecha: fecha, tipo: tipo, semana: 1);

  group('diferencias contra el día 0', () {
    setUp(() async {
      await repositorio.guardarMedicion(
        Medicion(
          semana: 0,
          fecha: DateTime(2026, 10, 19),
          pesoKg: 75,
          cinturaCm: 90,
          flexiones: 10,
          planchaSegundos: 30,
          metros12Min: 1500,
        ),
      );
      await repositorio.guardarMedicion(
        Medicion(
          semana: 4,
          fecha: DateTime(2026, 11, 16),
          pesoKg: 72.4,
          cinturaCm: 88.5,
          flexiones: 14,
          planchaSegundos: 45,
          metros12Min: 1700,
        ),
      );
    });

    test('muestra cada diferencia con signo y redondeada', () {
      final semana4 = momento(4);
      expect(
        semana4.diferencia(CampoMedicion.peso)?.texto,
        '−2,6 kg vs. día 0',
      );
      expect(
        semana4.diferencia(CampoMedicion.cintura)?.texto,
        '−1,5 cm vs. día 0',
      );
      expect(
        semana4.diferencia(CampoMedicion.flexiones)?.texto,
        '+4 rep vs. día 0',
      );
      expect(
        semana4.diferencia(CampoMedicion.plancha)?.texto,
        '+15 s vs. día 0',
      );
      expect(
        semana4.diferencia(CampoMedicion.prueba12Minutos)?.texto,
        '+200 m vs. día 0',
      );
    });

    test('en peso y cintura que baje es buena señal, en el resto que suba', () {
      final semana4 = momento(4);
      expect(semana4.diferencia(CampoMedicion.peso)?.buenaSenal, isTrue);
      expect(semana4.diferencia(CampoMedicion.cintura)?.buenaSenal, isTrue);
      expect(semana4.diferencia(CampoMedicion.flexiones)?.buenaSenal, isTrue);
    });

    test('si el peso sube no cuenta como buena señal', () async {
      await repositorio.guardarMedicion(
        Medicion(semana: 8, fecha: reloj, pesoKg: 76, flexiones: 10),
      );
      final semana8 = momento(8);
      expect(semana8.diferencia(CampoMedicion.peso)?.texto, '+1 kg vs. día 0');
      expect(semana8.diferencia(CampoMedicion.peso)?.buenaSenal, isFalse);
      expect(
        semana8.diferencia(CampoMedicion.flexiones)?.texto,
        'Igual que el día 0',
      );
      expect(semana8.diferencia(CampoMedicion.flexiones)?.buenaSenal, isFalse);
    });

    test(
      'no hay diferencia en el día 0, en lo que falta ni sin día 0',
      () async {
        expect(momento(0).diferencia(CampoMedicion.peso), isNull);
        expect(momento(8).diferencia(CampoMedicion.peso), isNull);
        await repositorio.borrarMedicion(0);
        expect(momento(4).diferencia(CampoMedicion.peso), isNull);
      },
    );

    test('los valores se muestran con coma y sin ceros de más', () {
      expect(momento(4).textoDe(CampoMedicion.peso), '72,4 kg');
      expect(momento(0).textoDe(CampoMedicion.peso), '75 kg');
      expect(momento(8).textoDe(CampoMedicion.peso), '—');
    });
  });

  group('validación y parseo', () {
    test('acepta coma o punto como separador decimal', () {
      expect(CampoMedicion.peso.interpretar('72,5'), 72.5);
      expect(CampoMedicion.peso.interpretar('72.5'), 72.5);
      expect(CampoMedicion.peso.interpretar(' 72 '), 72);
      expect(CampoMedicion.cintura.interpretar('88,25'), 88.25);
    });

    test('rechaza lo que no es un número claro', () {
      expect(CampoMedicion.peso.interpretar(''), isNull);
      expect(CampoMedicion.peso.interpretar('abc'), isNull);
      expect(CampoMedicion.peso.interpretar('1e2'), isNull);
      expect(CampoMedicion.peso.interpretar('72,555'), isNull);
      expect(CampoMedicion.peso.interpretar('72,5,1'), isNull);
      expect(CampoMedicion.peso.interpretar('-72'), isNull);
      expect(CampoMedicion.flexiones.interpretar('12,5'), isNull);
    });

    test('los enteros no admiten decimales', () {
      expect(CampoMedicion.flexiones.interpretar('12'), 12);
      expect(
        CampoMedicion.flexiones.validar('12,5'),
        'Escribí un número entero',
      );
    });

    test('vacío es válido porque cada medida es opcional', () {
      expect(CampoMedicion.peso.validar(null), isNull);
      expect(CampoMedicion.peso.validar('  '), isNull);
    });

    test('controla el rango de cada medida', () {
      expect(CampoMedicion.peso.validar('72,5'), isNull);
      expect(
        CampoMedicion.peso.validar('29,9'),
        'Poné un valor entre 30 y 300',
      );
      expect(CampoMedicion.peso.validar('301'), 'Poné un valor entre 30 y 300');
      expect(CampoMedicion.peso.validar('72,5,1'), contains('coma o punto'));
      expect(
        CampoMedicion.plancha.validar('0'),
        'Poné un valor entre 1 y 1800',
      );
      expect(CampoMedicion.flexiones.validar('0'), isNull);
      expect(
        CampoMedicion.prueba12Minutos.validar('7000'),
        'Poné un valor entre 100 y 6000',
      );
    });

    test('guardar convierte el texto y usa la fecha de hoy', () async {
      final guardado = await viewModel.guardarMedicion(
        semana: 0,
        textos: {
          CampoMedicion.peso: '75,5',
          CampoMedicion.cintura: '90.5',
          CampoMedicion.flexiones: '10',
          CampoMedicion.plancha: '',
          CampoMedicion.prueba12Minutos: '1500',
        },
        nivelFlexiones: 2,
      );

      expect(guardado, isTrue);
      final medicion = repositorio.mediciones.single;
      expect(medicion.semana, 0);
      expect(medicion.fecha, DateTime(2026, 10, 19));
      expect(medicion.pesoKg, 75.5);
      expect(medicion.cinturaCm, 90.5);
      expect(medicion.flexiones, 10);
      expect(medicion.flexionesNivel, 2);
      expect(medicion.planchaSegundos, isNull);
      expect(medicion.metros12Min, 1500);
    });

    test('al editar conserva la fecha original', () async {
      await viewModel.guardarMedicion(
        semana: 0,
        textos: {CampoMedicion.peso: '75'},
      );
      reloj = DateTime(2026, 10, 25);
      await viewModel.guardarMedicion(
        semana: 0,
        textos: {CampoMedicion.peso: '74,8'},
      );

      final medicion = repositorio.mediciones.single;
      expect(medicion.fecha, DateTime(2026, 10, 19));
      expect(medicion.pesoKg, 74.8);
    });

    test('sin ningún dato no guarda nada', () async {
      final guardado = await viewModel.guardarMedicion(
        semana: 0,
        textos: {
          CampoMedicion.peso: '',
          CampoMedicion.cintura: 'abc',
          CampoMedicion.plancha: '9999',
        },
      );

      expect(guardado, isFalse);
      expect(repositorio.mediciones, isEmpty);
    });
  });

  group('momento pendiente', () {
    int? pendiente() {
      final marcados = viewModel.momentos.where(
        (candidato) => candidato.pendiente,
      );
      return marcados.isEmpty ? null : marcados.single.semana;
    }

    test('sin fecha de inicio no marca ninguno', () {
      expect(pendiente(), isNull);
    });

    test('marca el día 0 durante la semana 1 y se apaga al cargarlo', () async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
      expect(pendiente(), 0);

      await viewModel.guardarMedicion(
        semana: 0,
        textos: {CampoMedicion.peso: '75'},
      );
      expect(pendiente(), isNull);
    });

    test('marca las semanas 4, 8 y 13 cuando llegan', () async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));

      reloj = DateTime(2026, 11, 3); // semana 3
      expect(pendiente(), isNull);
      reloj = DateTime(2026, 11, 9); // lunes de la semana 4
      expect(pendiente(), 4);
      reloj = DateTime(2026, 12, 7); // semana 8
      expect(pendiente(), 8);
      reloj = DateTime(2027, 1, 11); // semana 13
      expect(pendiente(), 13);
      reloj = DateTime(2027, 1, 18); // semana 14: ya no se mide
      expect(pendiente(), isNull);
    });

    test('antes de que empiece el plan no marca ninguno', () async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 26));
      expect(pendiente(), isNull);
    });
  });

  group('resumen y racha', () {
    Future<void> guardarFuerza(List<DateTime> fechas) async {
      for (final fecha in fechas) {
        await repositorio.guardarSesion(
          sesion('fuerza-${fecha.toIso8601String()}', fecha),
        );
      }
    }

    setUp(
      () => reloj = DateTime(2026, 10, 28, 20),
    ); // miércoles de la semana del 26/10

    test('sin sesiones todo da cero', () {
      final resumen = viewModel.resumen;
      expect(resumen.sesiones, 0);
      expect(resumen.sesionesEstaSemana, 0);
      expect(resumen.rachaSemanas, 0);
    });

    test(
      'cuenta el total y las sesiones de esta semana, de lunes a domingo',
      () async {
        await guardarFuerza([
          DateTime(2026, 10, 25, 23),
          DateTime(2026, 10, 26, 7),
        ]);
        await repositorio.guardarSesion(
          sesion(
            'cardio',
            DateTime(2026, 11, 1, 22),
            tipo: TipoSesion.cardioSuave,
          ),
        );
        await guardarFuerza([DateTime(2026, 11, 2)]);

        final resumen = viewModel.resumen;
        expect(resumen.sesiones, 4);
        expect(resumen.sesionesEstaSemana, 2);
      },
    );

    test('la racha cuenta semanas seguidas con 3 sesiones de fuerza', () async {
      await guardarFuerza([
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 7), // semana incompleta: corta la racha
        DateTime(2026, 10, 12), DateTime(2026, 10, 14), DateTime(2026, 10, 16),
        DateTime(2026, 10, 19), DateTime(2026, 10, 21), DateTime(2026, 10, 23),
      ]);

      expect(viewModel.resumen.rachaSemanas, 2);
    });

    test(
      'la semana en curso incompleta no corta la racha y completa suma',
      () async {
        await guardarFuerza([
          DateTime(2026, 10, 19),
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 23),
          DateTime(2026, 10, 26),
        ]);
        expect(viewModel.resumen.rachaSemanas, 1);

        await guardarFuerza([DateTime(2026, 10, 27), DateTime(2026, 10, 28)]);
        expect(viewModel.resumen.rachaSemanas, 2);
      },
    );

    test('si falta la semana anterior la racha vuelve a cero', () async {
      await guardarFuerza([
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 28),
      ]);
      expect(viewModel.resumen.rachaSemanas, 1);

      reloj = DateTime(
        2026,
        11,
        11,
      ); // dos semanas después, sin entrenar la del 2/11
      expect(viewModel.resumen.rachaSemanas, 0);
    });

    test('el cardio no cuenta para la racha', () async {
      for (final dia in [19, 21, 23]) {
        await repositorio.guardarSesion(
          sesion(
            'cardio-$dia',
            DateTime(2026, 10, dia),
            tipo: TipoSesion.intervalos,
          ),
        );
      }
      expect(viewModel.resumen.rachaSemanas, 0);
    });
  });

  group('historial', () {
    test('lista las sesiones más recientes primero', () async {
      await repositorio.guardarSesion(sesion('vieja', DateTime(2026, 10, 19)));
      await repositorio.guardarSesion(sesion('nueva', DateTime(2026, 10, 21)));

      expect(viewModel.sesiones.map((registro) => registro.id), [
        'nueva',
        'vieja',
      ]);
    });

    test('resume fuerza con ejercicios y series, y cardio con minutos', () {
      final fuerza = RegistroSesion(
        id: 'a',
        fecha: reloj,
        tipo: TipoSesion.fuerzaA,
        semana: 1,
        ejercicios: const [
          RegistroEjercicio(
            ejercicioId: 'flexiones',
            nivel: 1,
            repeticiones: [12, 11],
          ),
          RegistroEjercicio(
            ejercicioId: 'plancha_frontal',
            nivel: 2,
            repeticiones: [30],
          ),
        ],
      );
      final unaSerie = RegistroSesion(
        id: 'b',
        fecha: reloj,
        tipo: TipoSesion.fuerzaB,
        semana: 1,
        ejercicios: const [
          RegistroEjercicio(
            ejercicioId: 'flexiones',
            nivel: 1,
            repeticiones: [12],
          ),
        ],
      );
      final cardio = RegistroSesion(
        id: 'c',
        fecha: reloj,
        tipo: TipoSesion.cardioSuave,
        semana: 1,
        duracionMinutos: 25,
      );

      expect(viewModel.resumenDeSesion(fuerza), '2 ejercicios, 3 series');
      expect(viewModel.resumenDeSesion(unaSerie), '1 ejercicio, 1 serie');
      expect(viewModel.resumenDeSesion(cardio), '25 min');
      expect(
        viewModel.resumenDeSesion(
          sesion('d', reloj, tipo: TipoSesion.descansoActivo),
        ),
        'Sin duración anotada',
      );
    });

    test('el detalle trae nombre, nivel y repeticiones por serie', () {
      final registro = RegistroSesion(
        id: 'a',
        fecha: reloj,
        tipo: TipoSesion.fuerzaA,
        semana: 1,
        ejercicios: const [
          RegistroEjercicio(
            ejercicioId: 'flexiones',
            nivel: 2,
            repeticiones: [12, 11],
          ),
          RegistroEjercicio(
            ejercicioId: 'plancha_frontal',
            nivel: 1,
            repeticiones: [30, 28],
          ),
          RegistroEjercicio(
            ejercicioId: 'inexistente',
            nivel: 9,
            repeticiones: [],
          ),
        ],
      );

      final lineas = viewModel.ejerciciosDe(registro);

      expect(lineas[0].nombre, 'Flexiones de brazos');
      expect(lineas[0].nivel, 'Nivel 2 · En el piso');
      expect(lineas[0].series, '2 × 12, 11');
      expect(lineas[1].series, '2 × 30, 28 s');
      expect(lineas[2].nombre, 'inexistente');
      expect(lineas[2].nivel, 'Nivel 9');
      expect(lineas[2].series, 'Sin series');
    });

    test('borrar saca la sesión y avisa a quien escucha', () async {
      await repositorio.guardarSesion(sesion('uno', DateTime(2026, 10, 19)));
      await repositorio.guardarSesion(sesion('dos', DateTime(2026, 10, 21)));
      var avisos = 0;
      viewModel.addListener(() => avisos++);

      await viewModel.borrarSesion('uno');

      expect(viewModel.sesiones.map((registro) => registro.id), ['dos']);
      expect(repositorio.sesiones, hasLength(1));
      expect(avisos, greaterThan(0));
    });
  });
}
