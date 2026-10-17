import 'dart:math' as matematica;

import '../models/ejercicio.dart';
import '../models/registro_sesion.dart';
import '../models/semana_plan.dart';
import 'plan_casa.dart';

/// Reglas del plan sobre fechas, semanas y series. Funciones puras, sin estado.
class Calendario {
  const Calendario._();

  static const totalSemanas = 13;

  /// Después de la semana 13 el ciclo se repite desde la 5.
  static const semanaInicioCiclo = 5;

  /// Momentos de medición: día 0 y semanas 4, 8 y 13.
  static const semanasDeMedicion = [0, 4, 8, 13];

  static const horasMinimasEntreFuerza = 48;

  static DateTime soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  static DateTime lunesDe(DateTime fecha) {
    final dia = soloFecha(fecha);
    return DateTime(dia.year, dia.month, dia.day - (dia.weekday - DateTime.monday));
  }

  /// Primer lunes desde hoy, contando hoy si es lunes.
  static DateTime proximoLunes(DateTime hoy) {
    final dia = soloFecha(hoy);
    final diasHastaLunes = (DateTime.monday - dia.weekday) % 7;
    return DateTime(dia.year, dia.month, dia.day + diasHastaLunes);
  }

  /// Semana absoluta del plan (1, 2, 3, ...). Nula si todavía no empezó.
  static int? semanaDelPlan(DateTime fechaInicio, DateTime hoy) {
    final lunesInicio = lunesDe(fechaInicio);
    final dia = soloFecha(hoy);
    final dias = DateTime.utc(dia.year, dia.month, dia.day)
        .difference(DateTime.utc(lunesInicio.year, lunesInicio.month, lunesInicio.day))
        .inDays;
    if (dias < 0) return null;
    return dias ~/ 7 + 1;
  }

  /// Semana del plan (1 a 13) que corresponde a una semana absoluta.
  static int semanaEfectiva(int semanaAbsoluta) {
    if (semanaAbsoluta <= totalSemanas) return semanaAbsoluta;
    final tamanoCiclo = totalSemanas - semanaInicioCiclo + 1;
    return semanaInicioCiclo + (semanaAbsoluta - totalSemanas - 1) % tamanoCiclo;
  }

  static SemanaPlan planDeLaSemana(int semanaAbsoluta) =>
      PlanCasa.semana(semanaEfectiva(semanaAbsoluta));

  /// Momento de medición de una semana absoluta: 0 en la semana 1 (día 0),
  /// 4, 8 o 13 en esas semanas, y nulo en el resto. No hay mediciones después de la 13.
  static int? medicionDeLaSemana(int semanaAbsoluta) {
    if (semanaAbsoluta == 1) return 0;
    if (semanaAbsoluta == 4 || semanaAbsoluta == 8 || semanaAbsoluta == 13) {
      return semanaAbsoluta;
    }
    return null;
  }

  /// Semanas impares hacen A-B-A y las pares B-A-B.
  static List<Rutina> rutinasDeLaSemana(int semanaEfectiva) => semanaEfectiva.isOdd
      ? const [Rutina.a, Rutina.b, Rutina.a]
      : const [Rutina.b, Rutina.a, Rutina.b];

  /// Rutina que toca según cuántas sesiones de fuerza ya hiciste esta semana.
  static Rutina rutinaSugerida(int semanaAbsoluta, int sesionesDeFuerzaHechas) {
    final rutinas = rutinasDeLaSemana(semanaEfectiva(semanaAbsoluta));
    return rutinas[matematica.min(sesionesDeFuerzaHechas, rutinas.length - 1)];
  }

  /// Series de un ejercicio en una semana. [semana] es la semana efectiva (1 a 13).
  static int seriesPara(Ejercicio ejercicio, int semana, {bool diaFlojo = false}) {
    int series;
    if (semana <= 2 || semana == totalSemanas) {
      series = 2;
    } else if (semana == 3) {
      series = ejercicio.orden <= 3 ? 3 : 2;
    } else if ((semana == 11 || semana == 12) && ejercicio.cuartaSerieSemanas11y12) {
      series = 4;
    } else {
      series = 3;
    }
    if (series > ejercicio.seriesTope && !ejercicio.cuartaSerieSemanas11y12) {
      series = ejercicio.seriesTope;
    }
    return diaFlojo ? matematica.min(series, 2) : series;
  }

  /// Sesión sugerida para un día. Los días son orientativos: el domingo no sugiere nada.
  /// [rutina] es la de fuerza que toca ese día.
  static TipoSesion? sesionDelDia(DateTime fecha, int semanaAbsoluta, Rutina rutina) {
    final plan = planDeLaSemana(semanaAbsoluta);
    return switch (fecha.weekday) {
      DateTime.monday ||
      DateTime.wednesday ||
      DateTime.friday =>
        rutina == Rutina.a ? TipoSesion.fuerzaA : TipoSesion.fuerzaB,
      DateTime.tuesday => TipoSesion.cardioSuave,
      DateTime.thursday => TipoSesion.descansoActivo,
      DateTime.saturday =>
        plan.tipoSabado == TipoSabado.intervalos ? TipoSesion.intervalos : TipoSesion.cardioSuave,
      _ => null,
    };
  }

  /// Verdadero si pasaron menos de 48 h desde la última sesión de fuerza.
  static bool descansoInsuficiente(DateTime? ultimaFuerza, DateTime ahora) {
    if (ultimaFuerza == null) return false;
    return ahora.difference(ultimaFuerza).inHours < horasMinimasEntreFuerza;
  }
}
