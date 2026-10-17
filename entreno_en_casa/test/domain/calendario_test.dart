import 'package:entreno_en_casa/domain/models/ejercicio.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/domain/plan/calendario.dart';
import 'package:entreno_en_casa/domain/plan/plan_casa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('semanas', () {
    test('el lunes de una fecha es el de su semana', () {
      expect(Calendario.lunesDe(DateTime(2026, 10, 17)), DateTime(2026, 10, 12));
      expect(Calendario.lunesDe(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
      expect(Calendario.lunesDe(DateTime(2026, 10, 25, 23, 59)), DateTime(2026, 10, 19));
    });

    test('próximo lunes cuenta hoy si es lunes', () {
      expect(Calendario.proximoLunes(DateTime(2026, 10, 17)), DateTime(2026, 10, 19));
      expect(Calendario.proximoLunes(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
      expect(Calendario.proximoLunes(DateTime(2026, 10, 20)), DateTime(2026, 10, 26));
    });

    test('semana del plan cuenta desde el lunes de inicio', () {
      final inicio = DateTime(2026, 10, 21); // miércoles: la semana 1 arranca el lunes 19
      expect(Calendario.semanaDelPlan(inicio, DateTime(2026, 10, 18)), isNull);
      expect(Calendario.semanaDelPlan(inicio, DateTime(2026, 10, 19)), 1);
      expect(Calendario.semanaDelPlan(inicio, DateTime(2026, 10, 25)), 1);
      expect(Calendario.semanaDelPlan(inicio, DateTime(2026, 10, 26)), 2);
      expect(Calendario.semanaDelPlan(inicio, DateTime(2027, 1, 17)), 13);
    });

    test('después de la 13 se repite desde la 5', () {
      expect(Calendario.semanaEfectiva(13), 13);
      expect(Calendario.semanaEfectiva(14), 5);
      expect(Calendario.semanaEfectiva(22), 13);
      expect(Calendario.semanaEfectiva(23), 5);
    });

    test('momentos de medición', () {
      expect(Calendario.medicionDeLaSemana(1), 0);
      expect(Calendario.medicionDeLaSemana(2), isNull);
      expect(Calendario.medicionDeLaSemana(4), 4);
      expect(Calendario.medicionDeLaSemana(8), 8);
      expect(Calendario.medicionDeLaSemana(13), 13);
      expect(Calendario.medicionDeLaSemana(17), isNull);
    });
  });

  group('rutinas', () {
    test('semanas impares A-B-A y pares B-A-B', () {
      expect(Calendario.rutinasDeLaSemana(1), [Rutina.a, Rutina.b, Rutina.a]);
      expect(Calendario.rutinasDeLaSemana(2), [Rutina.b, Rutina.a, Rutina.b]);
    });

    test('la sugerida avanza con las sesiones hechas y no se pasa de la tercera', () {
      expect(Calendario.rutinaSugerida(1, 0), Rutina.a);
      expect(Calendario.rutinaSugerida(1, 1), Rutina.b);
      expect(Calendario.rutinaSugerida(1, 2), Rutina.a);
      expect(Calendario.rutinaSugerida(1, 5), Rutina.a);
      expect(Calendario.rutinaSugerida(2, 0), Rutina.b);
    });
  });

  group('series', () {
    Ejercicio ejercicio(Rutina rutina, int orden) =>
        PlanCasa.ejerciciosDe(rutina).firstWhere((candidato) => candidato.orden == orden);

    test('semanas 1 y 2 y la 13: 2 series', () {
      for (final semana in [1, 2, 13]) {
        for (final ejercicioDelPlan in [...PlanCasa.ejerciciosA, ...PlanCasa.ejerciciosB]) {
          expect(Calendario.seriesPara(ejercicioDelPlan, semana), 2, reason: 'semana $semana');
        }
      }
    });

    test('semana 3: 3 series en los primeros 3 ejercicios y 2 en el resto', () {
      expect(Calendario.seriesPara(ejercicio(Rutina.a, 3), 3), 3);
      expect(Calendario.seriesPara(ejercicio(Rutina.a, 4), 3), 2);
      expect(Calendario.seriesPara(ejercicio(Rutina.b, 1), 3), 3);
      expect(Calendario.seriesPara(ejercicio(Rutina.b, 6), 3), 2);
    });

    test('semanas 4 a 10: 3 series, salvo la plancha lateral que siempre es 2', () {
      expect(Calendario.seriesPara(ejercicio(Rutina.a, 1), 4), 3);
      expect(Calendario.seriesPara(ejercicio(Rutina.a, 5), 8), 3);
      expect(Calendario.seriesPara(ejercicio(Rutina.a, 6), 8), 2);
    });

    test('semanas 11 y 12: 4 series en búlgara y flexiones, 3 en el resto', () {
      for (final semana in [11, 12]) {
        expect(Calendario.seriesPara(ejercicio(Rutina.a, 1), semana), 4);
        expect(Calendario.seriesPara(ejercicio(Rutina.a, 2), semana), 4);
        expect(Calendario.seriesPara(ejercicio(Rutina.a, 3), semana), 3);
        expect(Calendario.seriesPara(ejercicio(Rutina.b, 1), semana), 3);
      }
    });

    test('día flojo baja a 2 series', () {
      expect(Calendario.seriesPara(ejercicio(Rutina.a, 1), 11, diaFlojo: true), 2);
      expect(Calendario.seriesPara(ejercicio(Rutina.a, 1), 1, diaFlojo: true), 2);
    });
  });

  group('sesión del día', () {
    test('lunes, miércoles y viernes son de fuerza con la rutina que toca', () {
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 19), 1, Rutina.a), TipoSesion.fuerzaA);
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 21), 1, Rutina.b), TipoSesion.fuerzaB);
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 23), 1, Rutina.a), TipoSesion.fuerzaA);
    });

    test('martes suave, jueves descanso activo y domingo nada', () {
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 20), 1, Rutina.a), TipoSesion.cardioSuave);
      expect(
        Calendario.sesionDelDia(DateTime(2026, 10, 22), 1, Rutina.a),
        TipoSesion.descansoActivo,
      );
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 25), 1, Rutina.a), isNull);
    });

    test('el sábado es suave hasta la semana 4 e intervalos desde la 5', () {
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 24), 4, Rutina.a), TipoSesion.cardioSuave);
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 24), 5, Rutina.a), TipoSesion.intervalos);
      expect(Calendario.sesionDelDia(DateTime(2026, 10, 24), 13, Rutina.a), TipoSesion.cardioSuave);
    });
  });

  test('avisa si pasaron menos de 48 horas desde la última fuerza', () {
    final ultima = DateTime(2026, 10, 19, 18);
    expect(Calendario.descansoInsuficiente(null, ultima), isFalse);
    expect(Calendario.descansoInsuficiente(ultima, DateTime(2026, 10, 21, 17)), isTrue);
    expect(Calendario.descansoInsuficiente(ultima, DateTime(2026, 10, 21, 18)), isFalse);
  });

  group('plan', () {
    test('tiene 13 semanas numeradas y 6 ejercicios por rutina', () {
      expect(
        PlanCasa.semanas.map((semana) => semana.numero),
        List.generate(13, (indice) => indice + 1),
      );
      expect(PlanCasa.ejerciciosA.map((ejercicio) => ejercicio.orden), [1, 2, 3, 4, 5, 6]);
      expect(PlanCasa.ejerciciosB.map((ejercicio) => ejercicio.orden), [1, 2, 3, 4, 5, 6]);
      for (final ejercicio in [...PlanCasa.ejerciciosA, ...PlanCasa.ejerciciosB]) {
        expect(ejercicio.niveles, hasLength(3), reason: ejercicio.id);
        expect(PlanCasa.ejercicioPorId(ejercicio.id), same(ejercicio));
      }
    });

    test('trote desde cero según la semana', () {
      expect(PlanCasa.troteDesdeCero(1).texto, '6 vueltas de 1 min trotando + 2 min caminando');
      expect(PlanCasa.troteDesdeCero(4).texto, '6 vueltas de 2 min trotando + 1 min caminando');
      expect(PlanCasa.troteDesdeCero(6).texto, '3 vueltas de 5 min trotando + 1 min caminando');
      expect(PlanCasa.troteDesdeCero(7).texto, '20 min seguidos de trote suave');
      expect(PlanCasa.troteDesdeCero(9).trotarMin, 25);
      expect(PlanCasa.troteDesdeCero(13).trotarMin, 35);
    });
  });
}
