import 'package:flutter/material.dart';

import '../../view_models/fuerza_view_model.dart';

/// Lista plegable de pasos con casillas, para el calentamiento y la vuelta a la calma.
class SeccionTildable extends StatelessWidget {
  const SeccionTildable({
    super.key,
    required this.titulo,
    required this.lista,
    required this.alAlternar,
    this.nota,
  });

  final String titulo;
  final String? nota;
  final ListaTildable lista;
  final void Function(int indice) alAlternar;

  @override
  Widget build(BuildContext context) {
    final nota = this.nota;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(titulo),
        subtitle: Text('${lista.cantidadHecha} de ${lista.items.length}'),
        children: [
          if (nota != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text(nota)),
            ),
          for (var indice = 0; indice < lista.items.length; indice++)
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: lista.estaHecho(indice),
              onChanged: (_) => alAlternar(indice),
              title: Text(lista.items[indice]),
            ),
        ],
      ),
    );
  }
}
