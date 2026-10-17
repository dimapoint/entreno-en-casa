import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/ejercicio.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/ui/features/fuerza/views/pantalla_fuerza.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Monta un lanzador que empuja la pantalla, como hace el shell de la app.
  Future<void> abrir(
    WidgetTester tester, {
    Rutina rutina = Rutina.a,
    int semana = 3,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<RepositorioEntrenamiento>.value(
        value: repositorio,
        child: MaterialApp(
          // El splash por defecto carga un shader que el motor de pruebas no soporta.
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Builder(
            builder: (contexto) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(contexto).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PantallaFuerza(rutina: rutina, semana: semana),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> irA(WidgetTester tester, Finder objetivo) async {
    await tester.ensureVisible(objetivo);
    await tester.pump();
  }

  Future<void> hacerPrimeraSerie(WidgetTester tester) async {
    await irA(tester, find.text('Hecha').first);
    await tester.tap(find.text('Hecha').first);
    await tester.pump();
  }

  /// Desmonta la pantalla para que se libere el temporizador de descanso.
  Future<void> cerrar(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  testWidgets('muestra el encabezado, el consejo y los seis ejercicios', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Fuerza A'), findsOneWidget);
    expect(find.text('Semana 3 · Base'), findsOneWidget);
    expect(
      find.text('3 series en los primeros 3 ejercicios, 2 en el resto'),
      findsOneWidget,
    );
    expect(find.textContaining('Para ahorrar unos 10 min'), findsOneWidget);
    expect(find.textContaining('1. Sentadilla búlgara'), findsOneWidget);
    expect(find.textContaining('6. Plancha lateral'), findsOneWidget);
    expect(find.text('3 × 8–12 por pierna · descanso 90 s'), findsOneWidget);
    expect(find.text('2 × 20–30 s por lado · descanso 45 s'), findsOneWidget);

    await tester.tap(find.byTooltip('Descartar consejo'));
    await tester.pump();
    expect(find.textContaining('Para ahorrar unos 10 min'), findsNothing);
    await cerrar(tester);
  });

  testWidgets('pasada la semana 13 avisa que es el ciclo repetido', (
    tester,
  ) async {
    await abrir(tester, rutina: Rutina.b, semana: 15);

    expect(find.text('Fuerza B'), findsOneWidget);
    expect(find.text('Semana 15 · Construcción'), findsOneWidget);
    expect(
      find.text('Ciclo repetido: esta semana toca como la 6.'),
      findsOneWidget,
    );
    await cerrar(tester);
  });

  testWidgets(
    'dar una serie por hecha avanza el contador y muestra el descanso',
    (tester) async {
      await abrir(tester);

      expect(find.text('Serie 1 de 3'), findsNWidgets(3));
      await hacerPrimeraSerie(tester);
      await tester.pump();

      expect(find.text('Serie 2 de 3'), findsOneWidget);
      expect(find.text('Serie 1: 8'), findsOneWidget);
      expect(find.text('Descanso 01:30'), findsOneWidget);

      await tester.tap(find.text('Saltar'));
      await tester.pump();
      expect(find.textContaining('Descanso 0'), findsNothing);
      await cerrar(tester);
    },
  );

  testWidgets(
    'entra en 360 dp de ancho aunque el texto del sistema sea más grande',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrir(tester, rutina: Rutina.b);

      // Una falla de layout (desborde) en cualquier tarjeta o en el descanso rompe la prueba.
      await hacerPrimeraSerie(tester);
      expect(find.textContaining('Descanso'), findsWidgets);
      expect(tester.takeException(), isNull);
      await cerrar(tester);
    },
  );

  testWidgets('el día flojo deja 2 series por ejercicio', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Día flojo'));
    await tester.pump();

    expect(find.text('Serie 1 de 2'), findsNWidgets(6));
    await cerrar(tester);
  });

  testWidgets('la ficha técnica muestra las notas y resalta el nivel elegido', (
    tester,
  ) async {
    await abrir(tester);
    final boton = find.byTooltip('Ficha técnica: Flexiones de brazos');
    await irA(tester, boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Errores comunes: ', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Niveles'), findsOneWidget);
    expect(find.text('El que elegiste hoy'), findsOneWidget);
    await cerrar(tester);
  });

  testWidgets('no deja terminar una sesión sin series', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Terminar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text('Marcá al menos una serie para guardar la sesión.'),
      findsOneWidget,
    );
    expect(find.text('¿Cómo te sentiste?'), findsNothing);
    await cerrar(tester);
  });

  testWidgets('terminar guarda la sesión y cierra la pantalla', (tester) async {
    await abrir(tester, rutina: Rutina.b, semana: 4);
    await hacerPrimeraSerie(tester);
    await tester.pump();
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terminar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo te sentiste?'), findsOneWidget);

    final guardar = find.widgetWithText(FilledButton, 'Guardar sesión');
    expect(tester.widget<FilledButton>(guardar).onPressed, isNull);
    await tester.tap(find.widgetWithText(ChoiceChip, '8'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Buen día');
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    final sesion = repositorio.sesiones.single;
    expect(sesion.tipo, TipoSesion.fuerzaB);
    expect(sesion.semana, 4);
    expect(sesion.sensacion, 8);
    expect(sesion.notas, 'Buen día');
    expect(sesion.ejercicios.single.ejercicioId, 'zancadas_atras');
    expect(find.byType(PantallaFuerza), findsNothing);
    expect(find.text('Sesión guardada.'), findsOneWidget);
    await cerrar(tester);
  });

  testWidgets('con series sin guardar pide confirmación antes de salir', (
    tester,
  ) async {
    await abrir(tester);
    await hacerPrimeraSerie(tester);
    await tester.pump();
    await tester.tap(find.text('Saltar'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);

    await tester.tap(find.text('Seguir entrenando'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaFuerza), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaFuerza), findsNothing);
    expect(repositorio.sesiones, isEmpty);
    await cerrar(tester);
  });

  testWidgets('sin series cargadas se sale sin preguntar', (tester) async {
    await abrir(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(PantallaFuerza), findsNothing);
    expect(find.text('¿Salir sin guardar?'), findsNothing);
    await cerrar(tester);
  });
}
