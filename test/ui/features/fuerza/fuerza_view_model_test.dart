import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/ejercicio.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/domain/plan/plan_casa.dart';
import 'package:entreno_en_casa/ui/core/temporizador_fases.dart';
import 'package:entreno_en_casa/ui/features/fuerza/view_models/fuerza_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime reloj;
  late RepositorioEntrenamiento repositorio;
  late List<String> vibraciones;

  Ejercicio ejercicioA(int orden) => PlanCasa.ejerciciosA[orden - 1];
  Ejercicio ejercicioB(int orden) => PlanCasa.ejerciciosB[orden - 1];

  FuerzaViewModel crear({Rutina rutina = Rutina.a, int semana = 1}) => FuerzaViewModel(
        repositorio: repositorio,
        rutina: rutina,
        semana: semana,
        ahora: () => reloj,
      );

  List<int> seriesDelDia(FuerzaViewModel viewModel) =>
      viewModel.ejercicios.map(viewModel.seriesDe).toList();

  /// Guarda en el repositorio una sesión anterior de [rutina] con un solo ejercicio.
  Future<void> guardarPrevia(
    String id,
    DateTime fecha,
    String ejercicioId,
    int nivel,
    List<int> repeticiones, {
    bool diaFlojo = false,
    TipoSesion tipo = TipoSesion.fuerzaA,
  }) =>
      repositorio.guardarSesion(
        RegistroSesion(
          id: id,
          fecha: fecha,
          tipo: tipo,
          semana: 2,
          diaFlojo: diaFlojo,
          ejercicios: [
            RegistroEjercicio(ejercicioId: ejercicioId, nivel: nivel, repeticiones: repeticiones),
          ],
        ),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    reloj = DateTime(2026, 10, 19, 18);
    repositorio = RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(await SharedPreferences.getInstance()),
      api: ServicioApi(
        cliente: MockClient((_) async => http.Response('{}', 200)),
        urlBase: 'https://ejemplo.test',
      ),
      ahora: () => reloj,
    );
    await repositorio.iniciar();

    vibraciones = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (llamada) async {
        if (llamada.method == 'HapticFeedback.vibrate') vibraciones.add('${llamada.arguments}');
        return null;
      },
    );
  });

  tearDown(() {
    repositorio.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('series', () {
    test('semanas 1 y 2: 2 series en todo', () {
      for (final rutina in Rutina.values) {
        for (final semana in [1, 2]) {
          final viewModel = crear(rutina: rutina, semana: semana);
          expect(seriesDelDia(viewModel), [2, 2, 2, 2, 2, 2], reason: '${rutina.letra} s$semana');
          viewModel.dispose();
        }
      }
    });

    test('semana 3: 3 series en los 3 primeros ejercicios y 2 en el resto', () {
      for (final rutina in Rutina.values) {
        final viewModel = crear(rutina: rutina, semana: 3);
        expect(seriesDelDia(viewModel), [3, 3, 3, 2, 2, 2], reason: rutina.letra);
        viewModel.dispose();
      }
    });

    test('semana 11: 4 series en búlgara y flexiones, y la lateral sigue en 2', () {
      final viewModelA = crear(semana: 11);
      expect(seriesDelDia(viewModelA), [4, 4, 3, 3, 3, 2]);
      final viewModelB = crear(rutina: Rutina.b, semana: 11);
      expect(seriesDelDia(viewModelB), [3, 3, 3, 3, 3, 3]);
      viewModelA.dispose();
      viewModelB.dispose();
    });

    test('pasada la semana 13 se usa la semana efectiva y se avisa del ciclo repetido', () {
      final viewModel = crear(semana: 21); // la efectiva es la 12
      expect(viewModel.semana, 21);
      expect(viewModel.semanaEfectiva, 12);
      expect(viewModel.esCicloRepetido, isTrue);
      expect(seriesDelDia(viewModel), [4, 4, 3, 3, 3, 2]);
      expect(crear(semana: 13).esCicloRepetido, isFalse);
      viewModel.dispose();
    });

    test('día flojo baja a 2 series y al apagarlo vuelven las del plan', () {
      final viewModel = crear(semana: 11);
      var avisos = 0;
      viewModel.addListener(() => avisos++);

      viewModel.cambiarDiaFlojo(activo: true);
      expect(seriesDelDia(viewModel), [2, 2, 2, 2, 2, 2]);
      viewModel.cambiarDiaFlojo(activo: false);
      expect(seriesDelDia(viewModel), [4, 4, 3, 3, 3, 2]);
      expect(avisos, 2);
      viewModel.dispose();
    });
  });

  group('contador y series hechas', () {
    test('arranca en el piso del rango y después en la última marca', () {
      final viewModel = crear();
      final flexiones = ejercicioA(2);
      expect(viewModel.marcaDe(flexiones), 8);

      viewModel.sumarMarca(flexiones);
      viewModel.sumarMarca(flexiones);
      viewModel.completarSerie(flexiones);
      expect(viewModel.repeticionesHechas(flexiones), [10]);
      expect(viewModel.marcaDe(flexiones), 10);

      viewModel.restarMarca(flexiones);
      viewModel.completarSerie(flexiones);
      expect(viewModel.repeticionesHechas(flexiones), [10, 9]);
      viewModel.dispose();
    });

    test('las planchas cuentan de a 5 segundos', () {
      final viewModel = crear();
      final plancha = ejercicioA(5);
      expect(viewModel.marcaDe(plancha), 30);
      viewModel.sumarMarca(plancha);
      expect(viewModel.marcaDe(plancha), 35);
      viewModel.restarMarca(plancha);
      viewModel.restarMarca(plancha);
      expect(viewModel.marcaDe(plancha), 25);
      viewModel.dispose();
    });

    test('la marca no baja de 0 y una serie en 0 no se puede dar por hecha', () {
      final viewModel = crear();
      final flexiones = ejercicioA(2);
      for (var vez = 0; vez < 20; vez++) {
        viewModel.restarMarca(flexiones);
      }
      expect(viewModel.marcaDe(flexiones), 0);
      viewModel.completarSerie(flexiones);
      expect(viewModel.repeticionesHechas(flexiones), isEmpty);
      viewModel.dispose();
    });

    test('al completar las series del día no deja agregar más', () {
      final viewModel = crear(); // semana 1: 2 series
      final flexiones = ejercicioA(2);
      viewModel.completarSerie(flexiones);
      expect(viewModel.ejercicioCompleto(flexiones), isFalse);
      viewModel.completarSerie(flexiones);
      expect(viewModel.ejercicioCompleto(flexiones), isTrue);
      viewModel.completarSerie(flexiones);
      expect(viewModel.repeticionesHechas(flexiones), hasLength(2));
      viewModel.dispose();
    });

    test('deshacer saca la última serie', () {
      final viewModel = crear();
      final flexiones = ejercicioA(2);
      viewModel.completarSerie(flexiones);
      viewModel.sumarMarca(flexiones);
      viewModel.completarSerie(flexiones);
      viewModel.deshacerUltimaSerie(flexiones);
      expect(viewModel.repeticionesHechas(flexiones), [8]);
      viewModel.deshacerUltimaSerie(flexiones);
      viewModel.deshacerUltimaSerie(flexiones);
      expect(viewModel.repeticionesHechas(flexiones), isEmpty);
      viewModel.dispose();
    });
  });

  group('historial y progresión', () {
    test('sin historial: nivel 1 y sin "última vez"', () {
      final viewModel = crear();
      expect(viewModel.nivelDe(ejercicioA(2)), 1);
      expect(viewModel.ultimaVez(ejercicioA(2)), isNull);
      expect(viewModel.sugerenciaDe(ejercicioA(2)), isNull);
      viewModel.dispose();
    });

    test('el nivel y la última vez salen de la sesión más reciente con ese ejercicio', () async {
      await guardarPrevia('vieja', DateTime(2026, 10, 12), 'flexiones', 1, [8, 8]);
      await guardarPrevia('nueva', DateTime(2026, 10, 14), 'flexiones', 2, [10, 9]);
      await guardarPrevia('otra', DateTime(2026, 10, 16), 'sentadilla_bulgara', 3, [9, 9]);

      final viewModel = crear();
      expect(viewModel.nivelDe(ejercicioA(2)), 2);
      expect(viewModel.nivelDe(ejercicioA(1)), 3);
      expect(viewModel.nivelDe(ejercicioA(3)), 1);
      final ultima = viewModel.ultimaVez(ejercicioA(2))!;
      expect(ultima.repeticiones, [10, 9]);
      expect(ultima.nivel, 2);
      expect(ultima.fecha, DateTime(2026, 10, 14));
      viewModel.dispose();
    });

    test('sugiere subir de nivel si en todas las series llegó al tope', () async {
      // Flexiones: el tope es 15.
      await guardarPrevia('anterior', DateTime(2026, 10, 14), 'flexiones', 1, [15, 15, 15]);
      final viewModel = crear(semana: 4);
      final flexiones = ejercicioA(2);

      final sugerencia = viewModel.sugerenciaDe(flexiones)!;
      expect(sugerencia.nivelNuevo, 2);

      viewModel.elegirNivel(flexiones, 2);
      expect(viewModel.sugerenciaDe(flexiones), isNull);
      viewModel.dispose();
    });

    test('no sugiere nada si alguna serie quedó por debajo del tope', () async {
      await guardarPrevia('anterior', DateTime(2026, 10, 14), 'flexiones', 1, [15, 14, 15]);
      final viewModel = crear();
      expect(viewModel.sugerenciaDe(ejercicioA(2)), isNull);
      viewModel.dispose();
    });

    test('no sugiere nada si la sesión anterior fue un día flojo o de una sola serie', () async {
      await guardarPrevia('floja', DateTime(2026, 10, 14), 'flexiones', 1, [15, 15], diaFlojo: true);
      await guardarPrevia('corta', DateTime(2026, 10, 12), 'remo_mancuerna', 1, [15]);
      final viewModel = crear();
      expect(viewModel.sugerenciaDe(ejercicioA(2)), isNull);
      expect(viewModel.sugerenciaDe(ejercicioA(3)), isNull);
      viewModel.dispose();
    });

    test('en el nivel 3 sugiere velocidad o peso extra, sin subir de nivel', () async {
      await guardarPrevia('anterior', DateTime(2026, 10, 14), 'flexiones', 3, [15, 15, 15]);
      await guardarPrevia('plancha', DateTime(2026, 10, 15), 'plancha_frontal', 3, [45, 45]);
      final viewModel = crear();

      final flexiones = viewModel.sugerenciaDe(ejercicioA(2))!;
      expect(flexiones.nivelNuevo, isNull);
      expect(flexiones.texto, contains('pausa'));
      final plancha = viewModel.sugerenciaDe(ejercicioA(5))!;
      expect(plancha.nivelNuevo, isNull);
      expect(plancha.texto, contains('mochila'));
      viewModel.dispose();
    });

    test('elegir un nivel que no existe no cambia nada', () {
      final viewModel = crear();
      viewModel.elegirNivel(ejercicioA(2), 4);
      viewModel.elegirNivel(ejercicioA(2), 0);
      expect(viewModel.nivelDe(ejercicioA(2)), 1);
      viewModel.dispose();
    });
  });

  group('descanso', () {
    test('al completar una serie arranca con el descanso del ejercicio', () {
      final viewModel = crear();
      expect(viewModel.descanso, isNull);

      viewModel.completarSerie(ejercicioA(3)); // 60 s
      final descanso = viewModel.descanso!;
      expect(descanso.corriendo, isTrue);
      expect(descanso.fases.single.esDescanso, isTrue);
      expect(descanso.segundosRestantes, 60);

      viewModel.completarSerie(ejercicioA(1)); // 90 s
      expect(viewModel.descanso!.segundosRestantes, 90);
      viewModel.dispose();
    });

    test('suma 15 segundos a lo que queda', () {
      final viewModel = crear();
      viewModel.completarSerie(ejercicioA(3));
      reloj = reloj.add(const Duration(seconds: 20));

      viewModel.agregarTiempoDeDescanso();
      expect(viewModel.descanso!.segundosRestantes, 55);
      viewModel.dispose();
    });

    test('saltar lo cierra sin vibrar', () {
      final viewModel = crear();
      viewModel.completarSerie(ejercicioA(3));
      viewModel.cerrarDescanso();
      expect(viewModel.descanso, isNull);
      expect(vibraciones, isEmpty);
      viewModel.dispose();
    });

    test('al terminar el tiempo vibra fuerte, una sola vez', () {
      final viewModel = crear();
      viewModel.completarSerie(ejercicioA(3));
      final descanso = viewModel.descanso!;

      reloj = reloj.add(const Duration(seconds: 61));
      descanso.actualizar();
      descanso.actualizar();
      expect(descanso.estado, EstadoTemporizador.terminado);
      expect(vibraciones, ['HapticFeedbackType.heavyImpact']);
      viewModel.dispose();
    });
  });

  group('calentamiento, vuelta a la calma y consejo', () {
    test('las casillas se tildan y se destildan', () {
      final viewModel = crear();
      expect(viewModel.calentamiento.items, PlanCasa.calentamiento);
      expect(viewModel.vueltaALaCalma.items, PlanCasa.vueltaALaCalma);

      viewModel.alternarItem(viewModel.calentamiento, 0);
      viewModel.alternarItem(viewModel.calentamiento, 3);
      expect(viewModel.calentamiento.cantidadHecha, 2);
      expect(viewModel.calentamiento.estaHecho(3), isTrue);
      viewModel.alternarItem(viewModel.calentamiento, 3);
      expect(viewModel.calentamiento.estaHecho(3), isFalse);
      expect(viewModel.vueltaALaCalma.cantidadHecha, 0);
      viewModel.dispose();
    });

    test('el consejo se puede descartar y habla de los ejercicios de la rutina', () {
      final viewModelA = crear();
      final viewModelB = crear(rutina: Rutina.b);
      expect(viewModelA.consejoVisible, isTrue);
      expect(viewModelA.consejo, contains('búlgara'));
      expect(viewModelB.consejo, contains('zancadas'));

      viewModelA.descartarConsejo();
      expect(viewModelA.consejoVisible, isFalse);
      viewModelA.dispose();
      viewModelB.dispose();
    });
  });

  group('guardar la sesión', () {
    test('guarda tipo, semana absoluta y solo los ejercicios con series hechas', () async {
      final viewModel = crear(rutina: Rutina.b, semana: 24);
      final zancadas = ejercicioB(1);
      final fondos = ejercicioB(5);

      viewModel.elegirNivel(zancadas, 2);
      viewModel.completarSerie(zancadas);
      viewModel.sumarMarca(zancadas);
      viewModel.sumarMarca(zancadas);
      viewModel.completarSerie(zancadas);
      viewModel.completarSerie(fondos);
      viewModel.cambiarDiaFlojo(activo: true);
      reloj = reloj.add(const Duration(minutes: 47, seconds: 30));

      expect(viewModel.haySinGuardar, isTrue);
      final guardada = await viewModel.guardarSesion(sensacion: 8, notas: '  Me costó el final  ');
      expect(guardada, isTrue);
      expect(viewModel.haySinGuardar, isFalse);

      final sesion = repositorio.sesiones.single;
      expect(sesion.id, startsWith('sesion-'));
      expect(sesion.tipo, TipoSesion.fuerzaB);
      expect(sesion.semana, 24);
      expect(sesion.fecha, reloj);
      expect(sesion.diaFlojo, isTrue);
      expect(sesion.sensacion, 8);
      expect(sesion.notas, 'Me costó el final');
      expect(sesion.duracionMinutos, 47);
      expect(sesion.ejercicios.map((ejercicio) => ejercicio.ejercicioId), [
        'zancadas_atras',
        'fondos_silla',
      ]);
      expect(sesion.ejercicios.first.nivel, 2);
      expect(sesion.ejercicios.first.repeticiones, [10, 12]);
      expect(sesion.ejercicios.last.nivel, 1);
      expect(sesion.ejercicios.last.repeticiones, [8]);
      viewModel.dispose();
    });

    test('la rutina A se guarda como Fuerza A', () async {
      final viewModel = crear(semana: 3);
      viewModel.completarSerie(ejercicioA(1));
      await viewModel.guardarSesion(sensacion: 5);
      expect(repositorio.sesiones.single.tipo, TipoSesion.fuerzaA);
      expect(repositorio.sesiones.single.semana, 3);
      expect(repositorio.sesiones.single.notas, isEmpty);
      viewModel.dispose();
    });

    test('no guarda una sesión vacía', () async {
      final viewModel = crear();
      viewModel.alternarItem(viewModel.calentamiento, 0);
      expect(viewModel.puedeGuardar, isFalse);
      expect(viewModel.haySinGuardar, isFalse);

      expect(await viewModel.guardarSesion(sensacion: 7), isFalse);
      expect(repositorio.sesiones, isEmpty);

      viewModel.completarSerie(ejercicioA(1));
      viewModel.deshacerUltimaSerie(ejercicioA(1));
      expect(await viewModel.guardarSesion(sensacion: 7), isFalse);
      expect(repositorio.sesiones, isEmpty);
      viewModel.dispose();
    });

    test('guardar dos veces no duplica la sesión', () async {
      final viewModel = crear();
      viewModel.completarSerie(ejercicioA(1));
      final dobleToque = [
        viewModel.guardarSesion(sensacion: 7),
        viewModel.guardarSesion(sensacion: 7),
      ];
      expect(await Future.wait(dobleToque), [true, false]);
      expect(await viewModel.guardarSesion(sensacion: 7), isFalse);
      expect(repositorio.sesiones, hasLength(1));
      viewModel.dispose();
    });

    test('lo guardado alimenta la "última vez" de la próxima sesión', () async {
      final primera = crear();
      primera.elegirNivel(ejercicioA(2), 2);
      primera.completarSerie(ejercicioA(2));
      await primera.guardarSesion(sensacion: 7);
      primera.dispose();

      final segunda = crear(semana: 2);
      expect(segunda.nivelDe(ejercicioA(2)), 2);
      expect(segunda.ultimaVez(ejercicioA(2))!.repeticiones, [8]);
      segunda.dispose();
    });
  });
}
