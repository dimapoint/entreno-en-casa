import 'package:entreno_en_casa/data/repositories/repositorio_entrenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_almacenamiento.dart';
import 'package:entreno_en_casa/data/services/servicio_api.dart';
import 'package:entreno_en_casa/domain/models/medicion.dart';
import 'package:entreno_en_casa/domain/models/registro_sesion.dart';
import 'package:entreno_en_casa/ui/core/tema.dart';
import 'package:entreno_en_casa/ui/features/progreso/views/pantalla_progreso.dart';
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
      api: ServicioApi(cliente: MockClient((_) async => http.Response('', 500))),
      ahora: () => DateTime(2026, 10, 19, 9),
    );
    await repositorio.iniciar();
  });

  tearDown(() => repositorio.dispose());

  /// Pantalla de celular chico, para que cualquier desborde falle el test.
  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<RepositorioEntrenamiento>.value(
        value: repositorio,
        child: MaterialApp(
          // El shader de la onda de toque no está compilado para el motor de los tests.
          theme: Tema.claro().copyWith(splashFactory: NoSplash.splashFactory),
          home: const PantallaProgreso(),
        ),
      ),
    );
  }

  Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

  testWidgets('muestra los cuatro momentos y las instrucciones', (tester) async {
    await abrir(tester);

    expect(find.text('Cómo medir'), findsOneWidget);
    expect(find.text('Día 0'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pump();
    for (final titulo in ['Semana 4', 'Semana 8', 'Semana 13', 'Señales de que va bien']) {
      expect(find.text(titulo, skipOffstage: false), findsOneWidget);
    }
  });

  testWidgets('cargar una medición la guarda y la muestra', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Día 0'));
    await tester.pumpAndSettle();
    await tester.enterText(campo('Peso (kg)'), '72,5');
    await tester.enterText(campo('Flexiones (rep)'), '12');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repositorio.mediciones.single.pesoKg, 72.5);
    expect(repositorio.mediciones.single.flexiones, 12);
    expect(find.text('72,5 kg'), findsOneWidget);
    expect(find.text('12 rep'), findsOneWidget);
  });

  testWidgets('un valor fuera de rango muestra el error y no guarda', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Día 0'));
    await tester.pumpAndSettle();
    await tester.enterText(campo('Peso (kg)'), '500');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Poné un valor entre 30 y 300'), findsOneWidget);
    expect(repositorio.mediciones, isEmpty);
  });

  testWidgets('guardar sin ningún dato avisa y deja el formulario abierto', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Día 0'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Cargá al menos un valor para poder guardar.'), findsOneWidget);
    expect(repositorio.mediciones, isEmpty);
  });

  testWidgets('editar una medición carga los valores que ya tenía', (tester) async {
    await repositorio.guardarMedicion(
      Medicion(semana: 0, fecha: DateTime(2026, 10, 19), pesoKg: 75.5, flexiones: 10),
    );
    await abrir(tester);

    await tester.tap(find.text('Día 0'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextFormField>(campo('Peso (kg)')).controller?.text, '75,5');
    expect(tester.widget<TextFormField>(campo('Flexiones (rep)')).controller?.text, '10');
  });

  testWidgets('historial vacío muestra un mensaje amable', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay sesiones'), findsOneWidget);
  });

  testWidgets('historial muestra el resumen, abre el detalle y borra con confirmación',
      (tester) async {
    await repositorio.guardarSesion(RegistroSesion(
      id: 'sesion-1',
      fecha: DateTime(2026, 10, 19, 8),
      tipo: TipoSesion.fuerzaA,
      semana: 1,
      ejercicios: const [
        RegistroEjercicio(ejercicioId: 'flexiones', nivel: 2, repeticiones: [12, 11]),
      ],
      sensacion: 7,
      notas: 'Me sentí bien',
    ));
    await abrir(tester);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Fuerza A'), findsOneWidget);
    expect(find.text('1 ejercicio, 2 series'), findsOneWidget);
    expect(find.text('7/10'), findsOneWidget);

    await tester.tap(find.text('Fuerza A'));
    await tester.pumpAndSettle();
    expect(find.text('Flexiones de brazos'), findsOneWidget);
    expect(find.text('Nivel 2 · En el piso'), findsOneWidget);
    expect(find.text('2 × 12, 11'), findsOneWidget);
    expect(find.text('Me sentí bien'), findsOneWidget);

    await tester.tap(find.text('Borrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repositorio.sesiones, hasLength(1));

    await tester.tap(find.text('Borrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(repositorio.sesiones, isEmpty);
    expect(find.text('Todavía no hay sesiones'), findsOneWidget);
  });
}
