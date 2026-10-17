import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/domain/plan/plan_casa.dart';
import 'package:entreno_en_casa/ui/core/temporizador_fases.dart';
import 'package:entreno_en_casa/ui/features/cardio/view_models/cardio_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime reloj;
  late RepositorioEntrenamiento repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Martes: el plan marca el cardio suave con los minutos del martes.
    reloj = DateTime(2026, 10, 20, 10);
    repositorio = RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(await SharedPreferences.getInstance()),
      // Sin código de sincronización no se hace ninguna llamada.
      api: ServicioApi(cliente: MockClient((_) async => http.Response('', 500))),
      ahora: () => reloj,
    );
    addTearDown(repositorio.dispose);
  });

  CardioViewModel crear(TipoSesion tipo, int semana, {int? minutos}) {
    final viewModel = CardioViewModel(
      repositorio: repositorio,
      tipo: tipo,
      semana: semana,
      minutos: minutos,
      ahora: () => reloj,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  List<FaseTemporizador> fasesDe(CardioViewModel viewModel) => viewModel.controlador.fases;

  group('cardio suave', () {
    test('es una sola fase con la duración recibida', () {
      final fases = fasesDe(crear(TipoSesion.cardioSuave, 3, minutos: 25));
      expect(fases, hasLength(1));
      expect(fases.single.titulo, 'Cardio suave');
      expect(fases.single.segundos, 25 * 60);
      expect(fases.single.detalle, allOf(contains('4 a 5'), contains('115 a 135')));
    });

    test('sin minutos usa el martes del plan, y el sábado el del sábado', () {
      expect(crear(TipoSesion.cardioSuave, 3).controlador.duracionTotalSegundos, 30 * 60);

      reloj = DateTime(2026, 10, 24, 10);
      expect(crear(TipoSesion.cardioSuave, 2).controlador.duracionTotalSegundos, 20 * 60);
    });

    test('el sábado sin minutos de sábado cae en los del martes', () {
      reloj = DateTime(2026, 10, 24, 10);
      expect(crear(TipoSesion.cardioSuave, 5).controlador.duracionTotalSegundos, 35 * 60);
    });

    test('semana absoluta mayor a 13 usa la semana efectiva del plan', () {
      // La 14 es la 5 del ciclo: martes 35 min.
      expect(crear(TipoSesion.cardioSuave, 14).controlador.duracionTotalSegundos, 35 * 60);
    });

    test('desde cero en la semana 1: 6 vueltas de 1 min trotando y 2 caminando', () {
      final viewModel = crear(TipoSesion.cardioSuave, 1, minutos: 25)..cambiarDesdeCero(true);
      final fases = fasesDe(viewModel);
      expect(fases, hasLength(12));
      expect(fases.map((fase) => fase.titulo).take(4), ['Trotá', 'Caminá', 'Trotá', 'Caminá']);
      expect(fases[0].segundos, 60);
      expect(fases[1].segundos, 120);
      expect(viewModel.controlador.duracionTotalSegundos, 18 * 60);
    });

    test('desde cero en la semana 5: 3 vueltas de 5 min trotando y 1 caminando', () {
      final viewModel = crear(TipoSesion.cardioSuave, 5, minutos: 35)..cambiarDesdeCero(true);
      final fases = fasesDe(viewModel);
      expect(fases, hasLength(6));
      expect(fases[0].segundos, 5 * 60);
      expect(fases[1].segundos, 60);
      expect(fases[0].detalle, startsWith('Vuelta 1 de 3.'));
    });

    test('desde cero en la semana 8: 20 min de trote seguido, una sola fase', () {
      final viewModel = crear(TipoSesion.cardioSuave, 8, minutos: 40)..cambiarDesdeCero(true);
      final fases = fasesDe(viewModel);
      expect(fases, hasLength(1));
      expect(fases.single.segundos, 20 * 60);
      expect(fases.single.esDescanso, isFalse);
    });

    test('desde cero se puede apagar, pero no con la sesión en marcha', () {
      final viewModel = crear(TipoSesion.cardioSuave, 1, minutos: 25);
      var avisos = 0;
      viewModel.addListener(() => avisos++);

      viewModel.cambiarDesdeCero(true);
      expect(viewModel.desdeCero, isTrue);
      expect(avisos, 1);
      viewModel.cambiarDesdeCero(false);
      expect(fasesDe(viewModel), hasLength(1));

      viewModel.cambiarDesdeCero(true);
      viewModel.controlador.iniciar();
      viewModel.cambiarDesdeCero(false);
      expect(viewModel.desdeCero, isTrue);
      expect(fasesDe(viewModel), hasLength(12));
    });

    test('lo que pasa en el temporizador nuevo también avisa a la pantalla', () {
      final viewModel = crear(TipoSesion.cardioSuave, 1, minutos: 25)..cambiarDesdeCero(true);
      var avisos = 0;
      viewModel.addListener(() => avisos++);
      viewModel.controlador.iniciar();
      expect(avisos, 1);
    });

    test('las opciones solo se ofrecen en el cardio suave sin trote desde cero', () {
      final viewModel = crear(TipoSesion.cardioSuave, 1, minutos: 25);
      expect(viewModel.opciones, hasLength(4));
      viewModel.cambiarDesdeCero(true);
      expect(viewModel.opciones, isEmpty);
      expect(crear(TipoSesion.intervalos, 5).opciones, isEmpty);
      expect(crear(TipoSesion.intervalos, 5).permiteDesdeCero, isFalse);
    });
  });

  group('intervalos', () {
    // 5 min de entrada en calor + vueltas de 4 minutos + 1 min entre vueltas + 5 min de bajada.
    test('3 vueltas: 28 fases y 24 min', () {
      final viewModel = crear(TipoSesion.intervalos, 5);
      expect(fasesDe(viewModel), hasLength(28));
      expect(viewModel.controlador.duracionTotalSegundos, 24 * 60);
      expect(viewModel.aviso, isNull);
    });

    test('4 vueltas: 37 fases y 29 min', () {
      final viewModel = crear(TipoSesion.intervalos, 7);
      expect(fasesDe(viewModel), hasLength(37));
      expect(viewModel.controlador.duracionTotalSegundos, 29 * 60);
    });

    test('5 vueltas: 46 fases y 34 min', () {
      final viewModel = crear(TipoSesion.intervalos, 10);
      expect(fasesDe(viewModel), hasLength(46));
      expect(viewModel.controlador.duracionTotalSegundos, 34 * 60);
    });

    test('en la semana absoluta 14 (la 5 del ciclo) son 3 vueltas', () {
      expect(crear(TipoSesion.intervalos, 14).controlador.duracionTotalSegundos, 24 * 60);
    });

    test('estructura: entrada en calor, fuerte y pausa de 40 y 20 s, caminata, bajada', () {
      final fases = fasesDe(crear(TipoSesion.intervalos, 5));
      expect(fases.first.titulo, 'Entrada en calor');
      expect(fases.first.segundos, 300);
      expect(fases[1].titulo, 'Soga rápida o trote rápido en el lugar');
      expect(fases[1].segundos, 40);
      expect(fases[1].esDescanso, isFalse);
      expect(fases[1].detalle, allOf(startsWith('Vuelta 1 de 3.'), contains('160 lpm')));
      expect(fases[2].titulo, 'Pausa');
      expect(fases[2].segundos, 20);
      expect(fases[2].esDescanso, isTrue);
      expect(fases[3].titulo, 'Escaladores');
      expect(fases[3].detalle, contains('rodillas al pecho'));
      expect(fases.last.titulo, 'Bajá caminando');
      expect(fases.last.segundos, 300);
    });

    test('cada pausa dice qué viene, y no hay caminata después de la última vuelta', () {
      final fases = fasesDe(crear(TipoSesion.intervalos, 5));
      expect(fases[2].detalle, contains('escaladores'));
      expect(fases[4].detalle, contains('sentadillas'));
      expect(fases[6].detalle, contains('rodillas arriba'));
      expect(fases[8].detalle, contains('caminata entre vueltas'));
      expect(fases[9].titulo, 'Caminata');
      expect(fases[9].segundos, 60);

      expect(fases.where((fase) => fase.titulo == 'Caminata'), hasLength(2));
      expect(fases[fases.length - 2].detalle, contains('caminata para bajar'));
    });

    test('antes de la semana 5 se deja hacer con 3 vueltas y se avisa', () {
      final viewModel = crear(TipoSesion.intervalos, 2);
      expect(fasesDe(viewModel), hasLength(28));
      expect(viewModel.controlador.duracionTotalSegundos, 24 * 60);
      expect(viewModel.aviso, allOf(contains('semana 5'), contains('3 vueltas')));
    });
  });

  group('descanso activo', () {
    test('30 min de caminata y dos rondas de 5 min de movilidad con los pasos', () {
      final viewModel = crear(TipoSesion.descansoActivo, 4);
      final fases = fasesDe(viewModel);
      expect(fases, hasLength(3));
      expect(fases[0].segundos, 30 * 60);
      expect(fases[1].segundos, 5 * 60);
      expect(fases[2].segundos, 5 * 60);
      expect(viewModel.controlador.duracionTotalSegundos, 40 * 60);
      for (final paso in PlanCasa.movilidad) {
        expect(fases[1].detalle, contains(paso));
      }
      expect(viewModel.pasosDeMovilidad, PlanCasa.movilidad);
    });
  });

  group('guardar', () {
    test('usa los minutos reales, redondeados, y el tipo y la semana absoluta', () async {
      final viewModel = crear(TipoSesion.intervalos, 14);
      viewModel.controlador.iniciar();
      reloj = reloj.add(const Duration(minutes: 10, seconds: 40));
      viewModel.controlador.pausar();
      expect(viewModel.puedeGuardar, isTrue);
      expect(viewModel.duracionRealMinutos, 11);

      final guardada = await viewModel.guardar(sensacion: 8, notas: '  Me costó la vuelta 3  ');
      expect(guardada, isTrue);

      final sesion = repositorio.sesiones.single;
      expect(sesion.tipo, TipoSesion.intervalos);
      expect(sesion.semana, 14);
      expect(sesion.duracionMinutos, 11);
      expect(sesion.sensacion, 8);
      expect(sesion.notas, 'Me costó la vuelta 3');
      expect(sesion.fecha, reloj);
      expect(sesion.id, startsWith('sesion-'));
    });

    test('con menos de medio minuto igual guarda 1 minuto', () async {
      final viewModel = crear(TipoSesion.cardioSuave, 1, minutos: 25);
      viewModel.controlador.iniciar();
      reloj = reloj.add(const Duration(seconds: 10));
      viewModel.controlador.pausar();

      expect(await viewModel.guardar(sensacion: 5), isTrue);
      expect(repositorio.sesiones.single.duracionMinutos, 1);
    });

    test('sin nada hecho no guarda', () async {
      final viewModel = crear(TipoSesion.cardioSuave, 1, minutos: 25);
      expect(viewModel.puedeGuardar, isFalse);
      expect(await viewModel.guardar(sensacion: 5), isFalse);

      viewModel.controlador.iniciar();
      expect(viewModel.puedeGuardar, isFalse);
      expect(await viewModel.guardar(sensacion: 5), isFalse);

      reloj = reloj.add(const Duration(minutes: 3));
      viewModel.controlador.reiniciar();
      expect(await viewModel.guardar(sensacion: 5), isFalse);
      expect(repositorio.sesiones, isEmpty);
    });

    test('al terminar guarda la duración completa de la sesión', () async {
      final viewModel = crear(TipoSesion.descansoActivo, 4);
      viewModel.controlador.iniciar();
      reloj = reloj.add(const Duration(minutes: 41));
      viewModel.controlador.actualizar();
      expect(viewModel.controlador.estado, EstadoTemporizador.terminado);

      expect(await viewModel.guardar(sensacion: 10), isTrue);
      expect(repositorio.sesiones.single.duracionMinutos, 40);
      expect(repositorio.sesiones.single.notas, isEmpty);
    });

    test('dos toques seguidos no guardan dos veces', () async {
      final viewModel = crear(TipoSesion.cardioSuave, 1, minutos: 25);
      viewModel.controlador.iniciar();
      reloj = reloj.add(const Duration(minutes: 5));

      final resultados = await Future.wait([
        viewModel.guardar(sensacion: 7),
        viewModel.guardar(sensacion: 7),
      ]);
      expect(resultados, [true, false]);
      expect(repositorio.sesiones, hasLength(1));
    });
  });
}
