import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/ui/features/ajustes/views/pantalla_ajustes.dart';
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
      almacenamiento: ServicioAlmacenamiento(
        await SharedPreferences.getInstance(),
      ),
      api: ServicioApi(urlBase: ''),
    );
  });

  tearDown(() => repositorio.dispose());

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<RepositorioEntrenamiento>.value(
        value: repositorio,
        child: MaterialApp(theme: _temaDePrueba, home: const PantallaAjustes()),
      ),
    );
  }

  testWidgets('muestra las secciones y aclara que no hay servidor', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Fecha de inicio'), findsOneWidget);
    expect(find.text('Sincronización'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
    expect(
      find.textContaining('no tiene un servidor configurado'),
      findsOneWidget,
    );
    expect(find.textContaining('Aviso médico'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Sincronizar ahora'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('cabe en 360 dp con el texto grande', (tester) async {
    tester.view.physicalSize = const Size(360, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    await tester.pumpWidget(
      ChangeNotifierProvider<RepositorioEntrenamiento>.value(
        value: repositorio,
        child: MaterialApp(
          theme: _temaDePrueba,
          builder: (context, hijo) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: hijo!,
          ),
          home: const PantallaAjustes(),
        ),
      ),
    );

    expect(find.text('Cambiar fecha'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el código arranca oculto y se puede mostrar', (tester) async {
    await abrir(tester);
    bool oculto() =>
        tester.widget<TextField>(find.byType(TextField)).obscureText;

    expect(oculto(), isTrue);

    await tester.tap(find.byTooltip('Mostrar código'));
    await tester.pump();

    expect(oculto(), isFalse);
    expect(find.byTooltip('Ocultar código'), findsOneWidget);
  });

  testWidgets('guardar y quitar el código', (tester) async {
    await abrir(tester);
    FilledButton guardar() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar'),
    );
    expect(guardar().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'secreto');
    await tester.pump();
    expect(guardar().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    await tester.pump();
    expect(repositorio.codigoSync, 'secreto');
    expect(find.text('Código guardado'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Quitar código'));
    await tester.pump();
    await tester.pump();
    expect(repositorio.codigoSync, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('elegir la fecha de inicio la guarda', (tester) async {
    await abrir(tester);
    expect(find.text('Todavía no elegiste una fecha.'), findsOneWidget);

    await tester.tap(find.text('Elegir fecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(repositorio.fechaInicio, isNotNull);
    expect(find.text('Cambiar fecha'), findsOneWidget);
  });
}
