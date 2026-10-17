import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/ejercicio.dart';
import 'package:entreno_en_casa/domain/models/medicion.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/domain/models/semana_plan.dart';
import 'package:entreno_en_casa/ui/features/hoy/view_models/hoy_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

RegistroSesion _sesion(String id, DateTime fecha) =>
    RegistroSesion(id: id, fecha: fecha, tipo: TipoSesion.fuerzaA, semana: 1);

void main() {
  // La semana 1 arranca el lunes 19 de octubre de 2026.
  final inicio = DateTime(2026, 10, 19);

  late DateTime reloj;
  late RepositorioEntrenamiento repositorio;
  late HoyViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    reloj = DateTime(2026, 10, 17, 10); // sábado antes de arrancar
    repositorio = RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(await SharedPreferences.getInstance()),
      api: ServicioApi(urlBase: ''),
    );
    viewModel = HoyViewModel(repositorio: repositorio, ahora: () => reloj);
  });

  tearDown(() {
    viewModel.dispose();
    repositorio.dispose();
  });

  group('sin fecha de inicio', () {
    test('propone el próximo lunes y lo guarda', () async {
      expect(viewModel.etapa, EtapaHoy.sinFechaDeInicio);
      expect(viewModel.proximoLunes, DateTime(2026, 10, 19));

      await viewModel.arrancarElProximoLunes();

      expect(repositorio.fechaInicio, DateTime(2026, 10, 19));
      expect(viewModel.etapa, EtapaHoy.antesDeEmpezar);
    });

    test('permite elegir otra fecha', () async {
      await viewModel.elegirFechaDeInicio(DateTime(2026, 11, 4));

      expect(repositorio.fechaInicio, DateTime(2026, 11, 4));
      expect(viewModel.lunesDeInicio, DateTime(2026, 11, 2));
    });
  });

  group('antes del primer día', () {
    setUp(() => repositorio.guardarFechaInicio(DateTime(2026, 10, 21)));

    test('cuenta los días que faltan hasta el lunes de inicio', () {
      expect(viewModel.etapa, EtapaHoy.antesDeEmpezar);
      expect(viewModel.lunesDeInicio, inicio);
      expect(viewModel.diasQueFaltan, 2);
      expect(viewModel.cuentaRegresiva, 'Faltan 2 días');

      reloj = DateTime(2026, 10, 18, 22);
      expect(viewModel.cuentaRegresiva, 'Falta 1 día');
    });

    test('las casillas de preparativos son locales y avisan al cambiar', () {
      var avisos = 0;
      viewModel.addListener(() => avisos++);

      viewModel.alternarPreparativo(2);
      expect(viewModel.preparativoHecho(2), isTrue);
      expect(viewModel.preparativoHecho(0), isFalse);

      viewModel.alternarPreparativo(2);
      expect(viewModel.preparativoHecho(2), isFalse);
      expect(avisos, 2);
    });

    test('el lunes de inicio ya está en curso', () {
      reloj = DateTime(2026, 10, 19, 6);
      expect(viewModel.etapa, EtapaHoy.enCurso);
    });
  });

  group('en curso', () {
    setUp(() => repositorio.guardarFechaInicio(inicio));

    test('semana 1 un lunes: fuerza A con medición del día 0 pendiente', () {
      reloj = DateTime(2026, 10, 19, 8);

      expect(viewModel.etapa, EtapaHoy.enCurso);
      expect(viewModel.semana, 1);
      expect(viewModel.tituloDeLaSemana, 'Semana 1 de 13');
      expect(viewModel.cicloRepetido, isFalse);
      expect(viewModel.plan.fase, FasePlan.base);
      expect(viewModel.sesionDeHoy, TipoSesion.fuerzaA);
      expect(viewModel.rutinaDeHoy, Rutina.a);
      expect(viewModel.duracionDeHoy, '45 a 55 min');
      expect(viewModel.detalleDeHoy, startsWith('6 ejercicios'));
      expect(viewModel.avisarDescansoInsuficiente, isFalse);
      expect(viewModel.hizoSesionHoy, isFalse);
      expect(viewModel.medicionPendiente, 0);
    });

    test('la tira va de lunes a domingo y destaca hoy', () {
      reloj = DateTime(2026, 10, 21, 8);

      final dias = viewModel.dias;

      expect(dias.map((dia) => dia.fecha.day), [19, 20, 21, 22, 23, 24, 25]);
      expect(dias.map((dia) => dia.sesion), [
        TipoSesion.fuerzaA,
        TipoSesion.cardioSuave,
        TipoSesion.fuerzaB,
        TipoSesion.descansoActivo,
        TipoSesion.fuerzaA,
        TipoSesion.cardioSuave,
        null,
      ]);
      expect(dias.where((dia) => dia.esHoy).single.fecha.day, 21);
      expect(dias.any((dia) => dia.registrada), isFalse);
    });

    test('la sesión de fuerza hecha cambia la rutina sugerida y marca el día', () async {
      await repositorio.guardarSesion(_sesion('lunes', DateTime(2026, 10, 19, 10)));
      reloj = DateTime(2026, 10, 21, 12); // 50 h después

      expect(viewModel.rutinaDeHoy, Rutina.b);
      expect(viewModel.sesionDeHoy, TipoSesion.fuerzaB);
      expect(viewModel.avisarDescansoInsuficiente, isFalse);
      expect(viewModel.dias.map((dia) => dia.registrada), [
        true, false, false, false, false, false, false,
      ]);
    });

    test('avisa si pasaron menos de 48 h desde la última fuerza en un día de fuerza', () async {
      await repositorio.guardarSesion(_sesion('lunes', DateTime(2026, 10, 19, 10)));

      reloj = DateTime(2026, 10, 21, 8); // 46 h después
      expect(viewModel.sesionDeHoy?.esFuerza, isTrue);
      expect(viewModel.avisarDescansoInsuficiente, isTrue);

      reloj = DateTime(2026, 10, 21, 10); // justo 48 h
      expect(viewModel.avisarDescansoInsuficiente, isFalse);
    });

    test('no avisa en días de cardio aunque la fuerza sea reciente', () async {
      await repositorio.guardarSesion(_sesion('lunes', DateTime(2026, 10, 19, 20)));
      reloj = DateTime(2026, 10, 20, 8);

      expect(viewModel.sesionDeHoy, TipoSesion.cardioSuave);
      expect(viewModel.avisarDescansoInsuficiente, isFalse);
    });

    test('la fuerza de la semana anterior cuenta para el aviso pero no para la rutina', () async {
      await repositorio.guardarSesion(_sesion('domingo', DateTime(2026, 10, 25, 20)));
      reloj = DateTime(2026, 10, 26, 10); // lunes de la semana 2

      expect(viewModel.semana, 2);
      expect(viewModel.rutinaDeHoy, Rutina.b);
      expect(viewModel.avisarDescansoInsuficiente, isTrue);
    });

    test('martes y sábado de las semanas suaves usan los minutos del plan', () {
      reloj = DateTime(2026, 10, 20, 8);
      expect(viewModel.sesionDeHoy, TipoSesion.cardioSuave);
      expect(viewModel.minutosDeCardioSuave, 25);
      expect(viewModel.duracionDeHoy, '25 min');

      reloj = DateTime(2026, 10, 24, 8);
      expect(viewModel.sesionDeHoy, TipoSesion.cardioSuave);
      expect(viewModel.minutosDeCardioSuave, 20);
      expect(viewModel.duracionDeHoy, '20 min');
    });

    test('el jueves es descanso activo de 40 min', () {
      reloj = DateTime(2026, 10, 22, 8);

      expect(viewModel.sesionDeHoy, TipoSesion.descansoActivo);
      expect(viewModel.duracionDeHoy, '40 min');
    });

    test('sábado de intervalos desde la semana 5', () {
      reloj = DateTime(2026, 11, 21, 9); // sábado de la semana 5

      expect(viewModel.semana, 5);
      expect(viewModel.sesionDeHoy, TipoSesion.intervalos);
      expect(viewModel.duracionDeHoy, 'unos 24 min');
      expect(viewModel.detalleDeHoy, contains('3 vueltas'));
      expect(viewModel.medicionPendiente, isNull);
    });

    test('sábado de la semana 13 es una caminata de 30 min', () {
      reloj = DateTime(2027, 1, 16, 9);

      expect(viewModel.semana, 13);
      expect(viewModel.sesionDeHoy, TipoSesion.cardioSuave);
      expect(viewModel.minutosDeCardioSuave, 30);
    });

    test('el domingo es descanso total', () {
      reloj = DateTime(2026, 10, 25, 9);

      expect(viewModel.sesionDeHoy, isNull);
      expect(viewModel.duracionDeHoy, isNull);
      expect(viewModel.detalleDeHoy, isNull);
      expect(viewModel.avisarDescansoInsuficiente, isFalse);
      expect(viewModel.dias.last.esHoy, isTrue);
    });

    test('la medición de la semana 4 queda pendiente hasta que se carga', () async {
      reloj = DateTime(2026, 11, 9, 9); // lunes de la semana 4
      await repositorio.guardarMedicion(Medicion(semana: 0, fecha: inicio));

      expect(viewModel.semana, 4);
      expect(viewModel.medicionPendiente, 4);
      expect(viewModel.plan.hito, 'Primera medición');

      await repositorio.guardarMedicion(Medicion(semana: 4, fecha: reloj));
      expect(viewModel.medicionPendiente, isNull);
    });

    test('con el día 0 cargado la semana 1 no pide medir', () async {
      reloj = DateTime(2026, 10, 19, 9);
      await repositorio.guardarMedicion(Medicion(semana: 0, fecha: inicio));

      expect(viewModel.medicionPendiente, isNull);
    });

    test('las semanas sin medición no piden nada', () {
      reloj = DateTime(2026, 10, 26, 9); // semana 2

      expect(viewModel.medicionPendiente, isNull);
    });

    test('pasada la semana 13 el ciclo se repite desde la 5', () {
      reloj = DateTime(2027, 1, 18, 9); // lunes de la semana 14

      expect(viewModel.semana, 14);
      expect(viewModel.semanaEfectiva, 5);
      expect(viewModel.cicloRepetido, isTrue);
      expect(viewModel.tituloDeLaSemana, 'Semana 14');
      expect(viewModel.plan.numero, 5);
      expect(viewModel.medicionPendiente, isNull);
    });

    test('se actualiza solo cuando cambia el repositorio', () async {
      reloj = DateTime(2026, 10, 19, 18);
      var avisos = 0;
      viewModel.addListener(() => avisos++);

      await repositorio.guardarSesion(_sesion('hoy', DateTime(2026, 10, 19, 17)));

      expect(avisos, greaterThan(0));
      expect(viewModel.hizoSesionHoy, isTrue);
      expect(viewModel.sesionDeHoy, TipoSesion.fuerzaB);
    });

    test('refrescar avisa para recalcular con el reloj', () {
      var avisos = 0;
      viewModel.addListener(() => avisos++);

      viewModel.refrescar();

      expect(avisos, 1);
    });
  });
}
