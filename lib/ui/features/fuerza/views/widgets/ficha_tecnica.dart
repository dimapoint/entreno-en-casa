import 'package:flutter/material.dart';

import '../../../../../domain/models/ejercicio.dart';

Future<void> mostrarFichaTecnica(
  BuildContext context,
  Ejercicio ejercicio,
  int nivelElegido,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) =>
      _FichaTecnica(ejercicio: ejercicio, nivelElegido: nivelElegido),
);

class _FichaTecnica extends StatelessWidget {
  const _FichaTecnica({required this.ejercicio, required this.nivelElegido});

  final Ejercicio ejercicio;
  final int nivelElegido;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(ejercicio.nombre, style: tema.textTheme.titleLarge),
          for (final nota in ejercicio.notas)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${nota.titulo}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: nota.texto),
                ],
              ),
            ),
          Text('Niveles', style: tema.textTheme.titleMedium),
          for (var indice = 0; indice < ejercicio.niveles.length; indice++)
            ListTile(
              selected: nivelElegido == indice + 1,
              selectedTileColor: tema.colorScheme.primaryContainer,
              selectedColor: tema.colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: CircleAvatar(child: Text('${indice + 1}')),
              title: Text(ejercicio.niveles[indice]),
              subtitle: nivelElegido == indice + 1
                  ? const Text('El que elegiste hoy')
                  : null,
            ),
        ],
      ),
    );
  }
}
