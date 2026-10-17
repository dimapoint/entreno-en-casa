import 'package:flutter/material.dart';

import '../../../../domain/models/registro_sesion.dart';
import '../../../core/formato.dart';
import '../view_models/progreso_view_model.dart';
import 'detalle_sesion.dart';

class PestanaHistorial extends StatelessWidget {
  const PestanaHistorial({super.key, required this.viewModel});

  final ProgresoViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final sesiones = viewModel.sesiones;
          if (sesiones.isEmpty) return const _HistorialVacio();
          final resumen = viewModel.resumen;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sesiones.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, indice) => indice == 0
                ? _TarjetaResumen(resumen: resumen)
                : _TarjetaSesion(sesion: sesiones[indice - 1], viewModel: viewModel),
          );
        },
      );
}

class _HistorialVacio extends StatelessWidget {
  const _HistorialVacio();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 56, color: tema.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Todavía no hay sesiones', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Cuando termines una sesión, la vas a ver acá.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.resumen});

  final ResumenHistorial resumen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _Cifra(valor: resumen.sesiones, etiqueta: 'Sesiones')),
                Expanded(child: _Cifra(valor: resumen.sesionesEstaSemana, etiqueta: 'Esta semana')),
                Expanded(child: _Cifra(valor: resumen.rachaSemanas, etiqueta: 'Racha')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'La racha cuenta las semanas seguidas con '
              '${ProgresoViewModel.sesionesDeFuerzaPorSemana} sesiones de fuerza o más.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta});

  final int valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return MergeSemantics(
      child: Column(
        children: [
          Text(
            '$valor',
            style: tema.textTheme.headlineMedium?.copyWith(color: tema.colorScheme.primary),
          ),
          Text(etiqueta, style: tema.textTheme.labelMedium),
        ],
      ),
    );
  }
}

IconData _iconoDe(TipoSesion tipo) => switch (tipo) {
      TipoSesion.fuerzaA || TipoSesion.fuerzaB => Icons.fitness_center,
      TipoSesion.cardioSuave => Icons.directions_walk,
      TipoSesion.intervalos => Icons.bolt,
      TipoSesion.descansoActivo => Icons.self_improvement,
    };

class _TarjetaSesion extends StatelessWidget {
  const _TarjetaSesion({required this.sesion, required this.viewModel});

  final RegistroSesion sesion;
  final ProgresoViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final apagado = tema.colorScheme.onSurfaceVariant;
    final sensacion = sesion.sensacion;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirDetalleSesion(context, viewModel, sesion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: tema.colorScheme.primaryContainer,
                foregroundColor: tema.colorScheme.onPrimaryContainer,
                child: Icon(_iconoDe(sesion.tipo)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sesion.tipo.etiqueta, style: tema.textTheme.titleMedium),
                    Text(
                      '${conPrimeraMayuscula(nombreDia(sesion.fecha.weekday))} '
                      '${fechaCorta(sesion.fecha)} · Semana ${sesion.semana}',
                      style: tema.textTheme.bodySmall?.copyWith(color: apagado),
                    ),
                    Text(viewModel.resumenDeSesion(sesion), style: tema.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (sensacion != null) ...[
                const SizedBox(width: 12),
                MergeSemantics(
                  child: Column(
                    children: [
                      Text(
                        '$sensacion/10',
                        semanticsLabel: '$sensacion de 10',
                        style: tema.textTheme.titleMedium?.copyWith(color: tema.colorScheme.primary),
                      ),
                      Text('sensación', style: tema.textTheme.labelSmall?.copyWith(color: apagado)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
