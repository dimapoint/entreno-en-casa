import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/ui/core/pantalla_principal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// El shader de InkSparkle no está disponible en flutter test.
final _temaDePrueba = ThemeData(splashFactory: NoSplash.splashFactory);

void main() {
  late RepositorioEntrenamiento repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repositorio = RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(await SharedPreferences.getInstance()),
      api: ServicioApi(urlBase: ''),
    );
    // Dentro de un mes: Hoy muestra la lista de antes de empezar, que no depende del día de la semana.
    await repositorio.guardarFechaInicio(DateTime.now().add(const Duration(days: 30)));
  });

  tearDown(() => repositorio.dispose());

  Future<void> abrir(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<RepositorioEntrenamiento>.value(
        value: repositorio,
        child: MaterialApp(theme: _temaDePrueba, home: const PantallaPrincipal()),
      ),
    );
  }

  int pestanaActual(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index!;

  Finder destino(Type contenedor, String etiqueta) =>
      find.descendant(of: find.byType(contenedor), matching: find.text(etiqueta));

  testWidgets('en el celular usa la barra inferior y cambia de pestaña', (tester) async {
    await abrir(tester, const Size(400, 1400));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(pestanaActual(tester), 0);

    for (final (indice, etiqueta) in [(1, 'Progreso'), (2, 'Guía'), (3, 'Ajustes'), (0, 'Hoy')]) {
      await tester.tap(destino(NavigationBar, etiqueta));
      await tester.pump();
      expect(pestanaActual(tester), indice, reason: etiqueta);
    }
  });

  testWidgets('Hoy lleva a Progreso y las pestañas conservan su estado', (tester) async {
    await abrir(tester, const Size(400, 1400));

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    await tester.tap(find.text('Ir a Progreso'));
    await tester.pump();
    expect(pestanaActual(tester), 1);

    await tester.tap(destino(NavigationBar, 'Hoy'));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile).first).value, isTrue);
  });

  testWidgets('en pantallas anchas usa el riel y centra el contenido en 720 dp', (tester) async {
    await abrir(tester, const Size(1280, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.getSize(find.byType(IndexedStack).first).width, 720);

    await tester.tap(destino(NavigationRail, 'Guía'));
    await tester.pump();
    expect(pestanaActual(tester), 2);
  });

  testWidgets('al cruzar el ancho del riel no se pierde la pestaña', (tester) async {
    await abrir(tester, const Size(1280, 800));
    await tester.tap(destino(NavigationRail, 'Ajustes'));
    await tester.pump();

    tester.view.physicalSize = const Size(400, 800);
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(pestanaActual(tester), 3);
  });
}
