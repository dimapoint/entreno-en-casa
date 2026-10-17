import 'package:flutter/material.dart';

import '../../../../core/formato.dart';
import '../../../../core/temporizador_fases.dart';

class BarraDescanso extends StatelessWidget {
  const BarraDescanso({
    super.key,
    required this.controlador,
    required this.alAgregarTiempo,
    required this.alCerrar,
  });

  final ControladorFases controlador;
  final VoidCallback alAgregarTiempo;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return ListenableBuilder(
      listenable: controlador,
      builder: (contexto, _) {
        final terminado = controlador.estado == EstadoTemporizador.terminado;
        final tiempo = minutosYSegundos(controlador.segundosRestantes);
        return Material(
          color: colores.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: colores.onSecondaryContainer),
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    terminado ? Icons.check_circle_outline : Icons.timer_outlined,
                    color: colores.onSecondaryContainer,
                  ),
                  Expanded(
                    child: Semantics(
                      label: terminado ? 'Terminó el descanso' : 'Descanso, quedan $tiempo',
                      excludeSemantics: true,
                      child: Text(
                        terminado ? 'Terminó el descanso' : 'Descanso $tiempo',
                        style: tema.textTheme.titleMedium?.copyWith(
                          color: colores.onSecondaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colores.onSecondaryContainer,
                      minimumSize: const Size.square(48),
                    ),
                    onPressed: alAgregarTiempo,
                    child: const Text('+15 s'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colores.onSecondaryContainer,
                      minimumSize: const Size.square(48),
                    ),
                    onPressed: alCerrar,
                    child: Text(terminado ? 'Cerrar' : 'Saltar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
