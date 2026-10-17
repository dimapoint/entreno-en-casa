import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/ui/features/cardio/views/pantalla_cardio.dart';
import 'package:entreno_en_casa/ui/features/fuerza/views/pantalla_fuerza.dart';
import 'package:entreno_en_casa/ui/features/hoy/views/pantalla_hoy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// El shader de InkSparkle no está disponible en flutter test.
final _temaDePrueba = ThemeData(splashFactory: NoSplash.splashFactory);

void main() {
  late RepositorioEntrenamiento repositorio;
  var visitasAProgreso = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    visitasAProgreso = 0;
    repositorio = RepositorioEntrenamiento(
      almacenamiento: ServicioAlmacenamiento(
        await SharedPreferences.getInstance(),
      ),
      api: ServicioApi(urlBase: ''),
    );
  });

  tearDown(() => repositorio.dispose());

  /// Celular alto para que no haga falta desplazar y se vea todo el contenido.
  Future<void> abrir(
    WidgetTester tester,
    DateTime ahora, {
    double ancho = 430,
    double escalaDeTexto = 1,
  }) async {
    tester.view.physicalSize = Size(ancho, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<RepositorioEntrenamiento>.value(
        value: repositorio,
        child: MaterialApp(
          theme: _temaDePrueba,
          builder: (context, hijo) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(escalaDeTexto)),
            child: hijo!,
          ),
          home: PantallaHoy(
            irAProgreso: () => visitasAProgreso++,
            ahora: () => ahora,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'sin fecha propone el lunes y al aceptar muestra la cuenta regresiva',
    (tester) async {
      await abrir(tester, DateTime(2026, 10, 17, 10));

      expect(find.text('Arrancar el lunes 19 de octubre'), findsOneWidget);
      expect(find.text('Elegir otra fecha'), findsOneWidget);

      await tester.tap(find.text('Arrancar el lunes 19 de octubre'));
      await tester.pump();

      expect(repositorio.fechaInicio, DateTime(2026, 10, 19));
      expect(find.text('Faltan 2 días'), findsOneWidget);
      expect(find.text('Antes del primer entrenamiento'), findsOneWidget);
    },
  );

  testWidgets('antes de empezar las casillas se marcan y llevan a Progreso', (
    tester,
  ) async {
    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    await abrir(tester, DateTime(2026, 10, 17, 10));

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
          .value,
      isTrue,
    );

    await tester.tap(find.text('Ir a Progreso'));
    expect(visitasAProgreso, 1);
  });

  testWidgets(
    'el primer lunes muestra fuerza A y empuja la pantalla de fuerza',
    (tester) async {
      await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
      await abrir(tester, DateTime(2026, 10, 19, 8));

      expect(find.text('Semana 1 de 13'), findsOneWidget);
      expect(find.text('Fuerza A'), findsOneWidget);
      expect(find.text('Duración: 45 a 55 min'), findsOneWidget);
      expect(find.text('Faltan las mediciones del día 0'), findsOneWidget);

      await tester.tap(find.text('Ir a Progreso'));
      expect(visitasAProgreso, 1);

      await tester.tap(find.text('Empezar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PantallaFuerza), findsOneWidget);
    },
  );

  testWidgets('el menú permite hacer cualquier otra sesión', (tester) async {
    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    await abrir(tester, DateTime(2026, 10, 19, 8));

    await tester.tap(find.text('Hacer otra sesión'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Intervalos'));
    // Con una sola tanda de cuadros la ruta nueva todavía no queda a la vista.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PantallaCardio), findsOneWidget);
  });

  testWidgets('el domingo es descanso total y no ofrece empezar', (
    tester,
  ) async {
    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    await abrir(tester, DateTime(2026, 10, 25, 9));

    expect(find.text('Descanso total'), findsOneWidget);
    expect(find.text('Empezar'), findsNothing);
  });

  testWidgets('pasada la semana 13 aclara cuál es la semana efectiva', (
    tester,
  ) async {
    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    await abrir(tester, DateTime(2027, 1, 18, 9));

    expect(find.text('Semana 14'), findsOneWidget);
    expect(find.text('Ciclo repetido: semana efectiva 5'), findsOneWidget);
  });

  testWidgets('cabe en 360 dp con el texto grande en cada etapa', (
    tester,
  ) async {
    await abrir(
      tester,
      DateTime(2026, 10, 17, 10),
      ancho: 360,
      escalaDeTexto: 1.5,
    );
    expect(tester.takeException(), isNull);

    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    await tester.pump();
    expect(find.text('Faltan 2 días'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Primer lunes con una fuerza de anoche: medición pendiente y aviso de 48 h juntos.
    await repositorio.guardarSesion(
      RegistroSesion(
        id: 'domingo',
        fecha: DateTime(2026, 10, 18, 20),
        tipo: TipoSesion.fuerzaB,
        semana: 1,
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await abrir(
      tester,
      DateTime(2026, 10, 19, 8),
      ancho: 360,
      escalaDeTexto: 1.5,
    );
    expect(find.textContaining('Pasaron menos de 48 h'), findsOneWidget);
    expect(find.text('Faltan las mediciones del día 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la nota de semana complicada se despliega', (tester) async {
    await repositorio.guardarFechaInicio(DateTime(2026, 10, 19));
    await abrir(tester, DateTime(2026, 10, 21, 9));

    expect(find.textContaining('Sostener el hábito'), findsNothing);

    await tester.tap(find.text('¿Semana complicada?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sostener el hábito'), findsOneWidget);
  });
}
