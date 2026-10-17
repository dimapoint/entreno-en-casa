import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/ui/features/cardio/views/pantalla_cardio.dart';
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
      almacenamiento: ServicioAlmacenamiento(await SharedPreferences.getInstance()),
      // Sin código de sincronización no se hace ninguna llamada.
      api: ServicioApi(cliente: MockClient((_) async => http.Response('', 500))),
    );
    addTearDown(repositorio.dispose);
  });

  /// La pantalla se abre con push desde una pantalla de partida, como en la app.
  Future<void> abrir(
    WidgetTester tester, {
    TipoSesion tipo = TipoSesion.intervalos,
    int semana = 5,
    int? minutos,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repositorio,
        child: MaterialApp(
          // Sin el shader del ripple, que en tests depende de cómo se compilaron los assets.
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PantallaCardio(tipo: tipo, semana: semana, minutos: minutos),
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

  /// El temporizador mide con el reloj real: hace falta que pase tiempo de verdad.
  Future<void> dejarPasarTiempoReal(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }

  testWidgets('muestra la sesión antes de arrancar y arranca, pausa y reanuda', (tester) async {
    await abrir(tester);

    expect(find.text('Listo para arrancar'), findsOneWidget);
    expect(find.text('Entrada en calor'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Así es la sesión (24 min)'), findsOneWidget);
    expect(find.text('Guardar lo hecho'), findsNothing);

    await tester.tap(find.text('Iniciar'));
    await tester.pump();
    expect(find.text('En marcha'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Así es la sesión (24 min)'), findsNothing);

    await tester.tap(find.text('Pausar'));
    await tester.pump();
    expect(find.text('Reanudar'), findsOneWidget);

    await tester.tap(find.text('Saltar fase'));
    await tester.pump();
    expect(find.text('Soga rápida o trote rápido en el lugar'), findsOneWidget);

    await tester.tap(find.text('Reiniciar'));
    await tester.pump();
    expect(find.text('Listo para arrancar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('avisa que el plan arranca los intervalos en la semana 5', (tester) async {
    await abrir(tester, semana: 2);
    expect(find.textContaining('semana 5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el interruptor de trote desde cero cambia la sesión', (tester) async {
    await abrir(tester, tipo: TipoSesion.cardioSuave, semana: 1, minutos: 25);
    expect(find.text('Así es la sesión (25 min)'), findsOneWidget);
    expect(find.text('Opciones para el cardio suave'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('Así es la sesión (18 min)'), findsOneWidget);
    expect(find.text('Trotá'), findsOneWidget);
    expect(find.text('Opciones para el cardio suave'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el descanso activo muestra los pasos de movilidad', (tester) async {
    await abrir(tester, tipo: TipoSesion.descansoActivo, semana: 4);
    expect(find.text('Movilidad, paso a paso'), findsOneWidget);
    expect(find.textContaining('Gato-camello'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sin haber hecho nada se sale directo', (tester) async {
    await abrir(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PantallaCardio), findsNothing);
  });

  testWidgets('con la sesión en marcha pide confirmar antes de salir', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Iniciar'));
    await dejarPasarTiempoReal(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);

    await tester.tap(find.text('Seguir acá'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaCardio), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaCardio), findsNothing);
    expect(repositorio.sesiones, isEmpty);
  });

  testWidgets('guardar lo hecho pide la sensación, guarda y cierra', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Iniciar'));
    await dejarPasarTiempoReal(tester);

    await tester.tap(find.text('Guardar lo hecho'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo te sentiste?'), findsOneWidget);
    expect(find.text('Vas a guardar 1 min.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Buena vuelta');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaCardio), findsNothing);
    final sesion = repositorio.sesiones.single;
    expect(sesion.tipo, TipoSesion.intervalos);
    expect(sesion.semana, 5);
    expect(sesion.duracionMinutos, 1);
    expect(sesion.sensacion, 7);
    expect(sesion.notas, 'Buena vuelta');
  });

  testWidgets('cancelar el formulario no guarda y deja la sesión en pausa', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Iniciar'));
    await dejarPasarTiempoReal(tester);

    await tester.tap(find.text('Guardar lo hecho'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaCardio), findsOneWidget);
    expect(find.text('Reanudar'), findsOneWidget);
    expect(repositorio.sesiones, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
