import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/plan/guia.dart';
import 'package:entreno_en_casa/ui/features/guia/view_models/guia_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sin código de sincronización el repositorio no toca la red.
Future<RepositorioEntrenamiento> _crearRepositorio() async {
  final repositorio = RepositorioEntrenamiento(
    almacenamiento: ServicioAlmacenamiento(
      await SharedPreferences.getInstance(),
    ),
    api: ServicioApi(
      cliente: MockClient((_) async => http.Response('{}', 200)),
      urlBase: 'https://ejemplo.test',
    ),
  );
  await repositorio.iniciar();
  return repositorio;
}

List<String> _titulos(GuiaViewModel viewModel) =>
    viewModel.seccionesVisibles.map((seccion) => seccion.titulo).toList();

void main() {
  late RepositorioEntrenamiento repositorio;
  late DateTime reloj;
  late GuiaViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    reloj = DateTime(2026, 10, 21, 9);
    repositorio = await _crearRepositorio();
    viewModel = GuiaViewModel(repositorio: repositorio, ahora: () => reloj);
  });

  tearDown(() {
    viewModel.dispose();
    repositorio.dispose();
  });

  group('búsqueda', () {
    test('sin texto muestra las nueve secciones en el orden del PDF', () {
      expect(_titulos(viewModel), [
        'Objetivo y antes de arrancar',
        'Semana tipo',
        'Calentamiento y vuelta a la calma',
        'Cómo progresar sin más peso',
        'Cardio',
        'Las 13 semanas',
        'Alimentación, sueño y recuperación',
        'Cómo medir el progreso',
        'Cuándo sumar peso',
      ]);
      expect(viewModel.buscando, isFalse);
    });

    test('ignora mayúsculas y tildes en lo que escribís y en el contenido', () {
      viewModel.buscar('alimentación');
      final conTilde = _titulos(viewModel);
      expect(conTilde, contains('Alimentación, sueño y recuperación'));
      for (final consulta in ['alimentacion', 'ALIMENTACION', 'ALIMENTACIÓN']) {
        viewModel.buscar(consulta);
        expect(_titulos(viewModel), conTilde, reason: consulta);
      }
    });

    test('la proteína solo aparece en la sección de alimentación', () {
      for (final consulta in ['proteina', 'PROTEÍNA', 'Proteína']) {
        viewModel.buscar(consulta);
        expect(_titulos(viewModel), [
          'Alimentación, sueño y recuperación',
        ], reason: consulta);
      }
    });

    test('encuentra texto de las tablas generadas desde el plan', () {
      viewModel.buscar('intensificacion');
      expect(_titulos(viewModel), contains('Las 13 semanas'));
      viewModel.buscar('bicho muerto');
      expect(_titulos(viewModel), contains('Cómo progresar sin más peso'));
    });

    test('con varias palabras la sección tiene que tener todas', () {
      viewModel.buscar('pulso charla');
      expect(_titulos(viewModel), ['Cardio']);
      viewModel.buscar('pulso proteina');
      expect(viewModel.seccionesVisibles, isEmpty);
    });

    test('sin coincidencias no queda ninguna sección', () {
      viewModel.buscar('zzzz');
      expect(viewModel.seccionesVisibles, isEmpty);
      expect(viewModel.buscando, isTrue);
    });

    test('borrar la búsqueda o dejar solo espacios vuelve a mostrar todo', () {
      viewModel.buscar('cardio');
      expect(viewModel.buscando, isTrue);
      viewModel.buscar('  ');
      expect(viewModel.buscando, isFalse);
      expect(viewModel.seccionesVisibles, hasLength(Guia.secciones.length));
    });

    test('avisa a la vista cuando cambia la búsqueda y no si es la misma', () {
      var avisos = 0;
      viewModel.addListener(() => avisos++);
      viewModel.buscar('cardio');
      viewModel.buscar('cardio');
      expect(avisos, 1);
    });
  });

  group('semana resaltada', () {
    test('sin fecha de inicio no hay semana', () {
      expect(viewModel.semanaActual, isNull);
      expect(viewModel.semanaResaltada, isNull);
    });

    test('antes del lunes de arranque no hay semana', () async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
      reloj = DateTime(2026, 10, 17);
      expect(viewModel.semanaResaltada, isNull);
    });

    test('la primera semana arranca el lunes de la fecha de inicio', () async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 21));
      expect(viewModel.semanaActual, 1);
      expect(viewModel.semanaResaltada, 1);
    });

    test('la semana 13 es la última del plan', () async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
      reloj = DateTime(2027, 1, 13);
      expect(viewModel.semanaActual, 13);
      expect(viewModel.semanaResaltada, 13);
    });

    test('después de la 13 se resalta la que repite desde la 5', () async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
      reloj = DateTime(2027, 1, 20);
      expect(viewModel.semanaActual, 14);
      expect(viewModel.semanaResaltada, 5);
      reloj = DateTime(2027, 1, 25);
      expect(viewModel.semanaActual, 15);
      expect(viewModel.semanaResaltada, 6);
    });

    test(
      'si cambia la fecha de inicio en el repositorio, avisa a la vista',
      () async {
        var avisos = 0;
        viewModel.addListener(() => avisos++);
        await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
        expect(avisos, greaterThan(0));
        expect(viewModel.semanaActual, 1);
      },
    );
  });

  group('contenido del PDF', () {
    final texto = Guia.secciones
        .map((seccion) => seccion.textoPlano)
        .join('\n');

    test('cada cifra clave está en los datos', () {
      const cifras = [
        '1,80 m',
        'unos 75 kg',
        '2 × 2 m',
        '48 h entre sesiones de fuerza',
        '25–45 min',
        '15 min de cardio suave al final',
        '2 sesiones de fuerza de 30 min',
        '8–10 min de calentamiento',
        '5 min de vuelta a la calma',
        '2 repeticiones más',
        '115–135 lpm',
        '160 lpm o más',
        '3 vueltas de 5 min trotando + 1 min caminando',
        '20 min seguidos de trote suave',
        '40 s fuerte y 20 s de pausa',
        '2 series, 2 repeticiones menos que la semana 12',
        'Segunda medición',
        'Tercera medición',
        '120–150 g de proteína',
        '120–130 g de proteína',
        '30–40 g de proteína',
        '2–3 L por día',
        '7–9 h',
        'más de 15 repeticiones limpias por pierna',
        'entre las semanas 7 y 10',
        '1 L pesa 1 kg',
        '10 botellas son 10 kg',
        'hasta 20 kg cada una',
      ];
      for (final cifra in cifras) {
        expect(texto, contains(cifra), reason: cifra);
      }
    });

    test('las tablas generadas cubren las 13 semanas y los 12 ejercicios', () {
      final tablas = Guia.secciones
          .expand((seccion) => seccion.bloques)
          .whereType<TablaGuia>()
          .toList();
      final semanas = tablas.singleWhere((tabla) => tabla.filasPorSemana);
      final niveles = tablas.singleWhere(
        (tabla) => tabla.encabezados.first == 'Ejercicio',
      );
      expect(semanas.filas, hasLength(13));
      expect(semanas.filas.first.first, 'Semana 1');
      expect(semanas.filas.last.first, 'Semana 13');
      expect(niveles.filas, hasLength(12));
      expect(
        niveles.filas.every(
          (fila) => fila.length == niveles.encabezados.length,
        ),
        isTrue,
      );
    });

    test('toda fila de toda tabla tiene una celda por encabezado', () {
      final tablas = Guia.secciones
          .expand((seccion) => seccion.bloques)
          .whereType<TablaGuia>();
      for (final tabla in tablas) {
        for (final fila in tabla.filas) {
          expect(fila, hasLength(tabla.encabezados.length), reason: fila.first);
        }
      }
    });
  });
}
