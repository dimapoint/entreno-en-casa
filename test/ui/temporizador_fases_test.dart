import 'package:entreno_en_casa/ui/core/temporizador_fases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime reloj;
  late List<String> avisos;
  var terminado = false;

  ControladorFases crear() => ControladorFases(
    const [
      FaseTemporizador(titulo: 'Fuerte', segundos: 40),
      FaseTemporizador(titulo: 'Pausa', segundos: 20, esDescanso: true),
    ],
    ahora: () => reloj,
    alCambiarFase: (fase) => avisos.add(fase.titulo),
    alTerminar: () => terminado = true,
  );

  setUp(() {
    reloj = DateTime(2026, 10, 19, 10);
    avisos = [];
    terminado = false;
  });

  test('cuenta con el reloj aunque nadie lo refresque en segundo plano', () {
    final controlador = crear()..iniciar();
    expect(controlador.segundosRestantes, 40);
    reloj = reloj.add(const Duration(seconds: 45));
    expect(controlador.indiceActual, 1);
    expect(controlador.segundosRestantes, 15);
    controlador.actualizar();
    expect(avisos, ['Fuerte', 'Pausa']);
    controlador.dispose();
  });

  test('termina y avisa una sola vez', () {
    final controlador = crear()..iniciar();
    reloj = reloj.add(const Duration(seconds: 61));
    controlador.actualizar();
    controlador.actualizar();
    expect(controlador.estado, EstadoTemporizador.terminado);
    expect(controlador.segundosRestantesTotal, 0);
    expect(terminado, isTrue);
    controlador.dispose();
  });

  test('pausar congela el tiempo y reanudar sigue desde ahí', () {
    final controlador = crear()..iniciar();
    reloj = reloj.add(const Duration(seconds: 10));
    controlador.pausar();
    reloj = reloj.add(const Duration(minutes: 5));
    expect(controlador.segundosRestantes, 30);
    controlador.reanudar();
    reloj = reloj.add(const Duration(seconds: 5));
    expect(controlador.segundosRestantes, 25);
    controlador.dispose();
  });

  test('saltar fase pasa a la siguiente y en la última termina', () {
    final controlador = crear()..iniciar();
    controlador.saltarFase();
    expect(controlador.indiceActual, 1);
    expect(controlador.segundosRestantes, 20);
    controlador.saltarFase();
    expect(controlador.estado, EstadoTemporizador.terminado);
    controlador.dispose();
  });

  test('reiniciar vuelve al principio', () {
    final controlador = crear()..iniciar();
    reloj = reloj.add(const Duration(seconds: 50));
    controlador.reiniciar();
    expect(controlador.estado, EstadoTemporizador.quieto);
    expect(controlador.indiceActual, 0);
    expect(controlador.segundosRestantes, 40);
    controlador.dispose();
  });
}
