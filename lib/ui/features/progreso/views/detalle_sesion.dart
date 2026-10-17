import 'package:flutter/material.dart';

import '../../../../domain/models/registro_sesion.dart';
import '../../../core/formato.dart';
import '../view_models/progreso_view_model.dart';

Future<void> abrirDetalleSesion(
  BuildContext context,
  ProgresoViewModel viewModel,
  RegistroSesion sesion,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DetalleSesion(viewModel: viewModel, sesion: sesion),
    );

class DetalleSesion extends StatelessWidget {
  const DetalleSesion({super.key, required this.viewModel, required this.sesion});

  final ProgresoViewModel viewModel;
  final RegistroSesion sesion;

  Future<void> _confirmarBorrado(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('¿Borrar esta sesión?'),
        content: const Text(
          'Se borra del historial y de tus otros dispositivos si usás sincronización. '
          'No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    Navigator.pop(context);
    await viewModel.borrarSesion(sesion.id);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sensacion = sesion.sensacion;
    final minutos = sesion.duracionMinutos;
    final ejercicios = viewModel.ejerciciosDe(sesion);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sesion.tipo.etiqueta, style: tema.textTheme.headlineSmall),
          Text(
            '${conPrimeraMayuscula(fechaLarga(sesion.fecha))} · Semana ${sesion.semana}',
            style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          if (sensacion != null || minutos != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (sensacion != null) Chip(label: Text('Sensación $sensacion/10')),
                if (minutos != null) Chip(label: Text('$minutos min')),
              ],
            ),
          ],
          if (ejercicios.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final ejercicio in ejercicios) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ejercicio.nombre, style: tema.textTheme.titleSmall),
                          Text(
                            ejercicio.nivel,
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(ejercicio.series, style: tema.textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ],
          if (sesion.notas.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Notas', style: tema.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(sesion.notas),
          ],
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _confirmarBorrado(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Borrar sesión'),
            style: TextButton.styleFrom(foregroundColor: tema.colorScheme.error),
          ),
        ],
      ),
    );
  }
}
