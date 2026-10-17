import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/plan/guia.dart';
import 'package:entreno_en_casa/ui/core/tema.dart';
import 'package:entreno_en_casa/ui/features/guia/views/pantalla_guia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _mostrar(
  WidgetTester tester,
  RepositorioEntrenamiento repositorio,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<RepositorioEntrenamiento>.value(
      value: repositorio,
      // El splash de Material 3 carga un shader que flutter_tester no trae.
      child: MaterialApp(
        theme: Tema.claro().copyWith(splashFactory: NoSplash.splashFactory),
        home: const PantallaGuia(),
      ),
    ),
  );
}

void main() {
  late RepositorioEntrenamiento repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repositorio = RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(
        await SharedPreferences.getInstance(),
      ),
      api: ServicioApi(
        cliente: MockClient((_) async => http.Response('{}', 200)),
        urlBase: 'https://ejemplo.test',
      ),
    );
    await repositorio.iniciar();
  });

  tearDown(() => repositorio.dispose());

  testWidgets(
    'muestra el aviso médico y las secciones a 360 px sin desbordes',
    (tester) async {
      await _mostrar(tester, repositorio);

      expect(
        find.textContaining('no reemplaza la consulta médica'),
        findsOneWidget,
      );
      for (final seccion in Guia.secciones) {
        expect(
          find.text(seccion.titulo),
          findsOneWidget,
          reason: seccion.titulo,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('abre cada sección sin desbordes y muestra su contenido', (
    tester,
  ) async {
    await _mostrar(tester, repositorio);

    for (final seccion in Guia.secciones) {
      await tester.ensureVisible(find.text(seccion.titulo));
      await tester.tap(find.text(seccion.titulo));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('120–150 g de proteína'), findsOneWidget);
    expect(find.textContaining('115–135 lpm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'buscar sin tildes deja las secciones que coinciden y se puede borrar',
    (tester) async {
      await _mostrar(tester, repositorio);

      await tester.enterText(find.byType(TextField), 'alimentacion');
      await tester.pumpAndSettle();
      expect(find.text('Alimentación, sueño y recuperación'), findsOneWidget);
      expect(find.text('Cardio'), findsNothing);
      expect(find.textContaining('120–150 g de proteína'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No encontramos nada'), findsOneWidget);

      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.byTooltip('Borrar búsqueda'), findsNothing);
    },
  );

  testWidgets(
    'con fecha de inicio resalta la semana actual en las 13 semanas',
    (tester) async {
      await repositorio.guardarFechaInicio(DateTime.now());
      await _mostrar(tester, repositorio);

      await tester.ensureVisible(find.text('Las 13 semanas'));
      await tester.tap(find.text('Las 13 semanas'));
      await tester.pumpAndSettle();

      expect(find.text('Estás en la semana 1.'), findsOneWidget);
      expect(find.text('Estás acá'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sin fecha de inicio no resalta ninguna semana', (tester) async {
    await _mostrar(tester, repositorio);

    await tester.ensureVisible(find.text('Las 13 semanas'));
    await tester.tap(find.text('Las 13 semanas'));
    await tester.pumpAndSettle();

    expect(find.text('Estás acá'), findsNothing);
    expect(find.textContaining('Semana 13'), findsOneWidget);
  });
}
