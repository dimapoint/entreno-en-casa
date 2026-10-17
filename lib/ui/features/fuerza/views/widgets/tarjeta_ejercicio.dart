import 'package:flutter/material.dart';

import '../../../../core/formato.dart';
import '../../../../../domain/models/ejercicio.dart';
import '../../view_models/fuerza_view_model.dart';
import 'ficha_tecnica.dart';

class TarjetaEjercicio extends StatelessWidget {
  const TarjetaEjercicio({super.key, required this.viewModel, required this.ejercicio});

  final FuerzaViewModel viewModel;
  final Ejercicio ejercicio;

  static const _tamanoTactil = Size.square(48);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final nivel = viewModel.nivelDe(ejercicio);
    final series = viewModel.seriesDe(ejercicio);
    final hechas = viewModel.repeticionesHechas(ejercicio);
    final ultimaVez = viewModel.ultimaVez(ejercicio);
    final sugerencia = viewModel.sugerenciaDe(ejercicio);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${ejercicio.orden}. ${ejercicio.nombre}',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Ficha técnica: ${ejercicio.nombre}',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => mostrarFichaTecnica(context, ejercicio, nivel),
                ),
              ],
            ),
            Text(
              '$series × ${ejercicio.repeticiones} · descanso ${ejercicio.descansoTexto}',
              style: tema.textTheme.bodyMedium,
            ),
            Text(
              ultimaVez == null
                  ? 'Primera vez con este ejercicio.'
                  : 'Última vez (${fechaCorta(ultimaVez.fecha)}), nivel ${ultimaVez.nivel}: '
                      '${ultimaVez.repeticiones.join(' · ')} ${ejercicio.esTiempo ? 's' : 'reps'}',
              style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
              segments: [
                for (var opcion = 1; opcion <= ejercicio.niveles.length; opcion++)
                  ButtonSegment(value: opcion, label: Text('Nivel $opcion')),
              ],
              selected: {nivel},
              onSelectionChanged: (elegidos) => viewModel.elegirNivel(ejercicio, elegidos.single),
            ),
            Text(ejercicio.niveles[nivel - 1], style: tema.textTheme.bodyMedium),
            if (sugerencia != null) _CuadroSugerencia(sugerencia, ejercicio, viewModel),
            if (hechas.isNotEmpty) _SeriesHechas(viewModel: viewModel, ejercicio: ejercicio),
            if (viewModel.ejercicioCompleto(ejercicio))
              Row(
                spacing: 8,
                children: [
                  Icon(Icons.check_circle, color: tema.colorScheme.primary),
                  Text('Ejercicio completo.', style: tema.textTheme.titleSmall),
                ],
              )
            else
              _Contador(viewModel: viewModel, ejercicio: ejercicio, serieActual: hechas.length + 1),
          ],
        ),
      ),
    );
  }
}

class _CuadroSugerencia extends StatelessWidget {
  const _CuadroSugerencia(this.sugerencia, this.ejercicio, this.viewModel);

  final Sugerencia sugerencia;
  final Ejercicio ejercicio;
  final FuerzaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final nivelNuevo = sugerencia.nivelNuevo;
    return Material(
      color: colores.tertiaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colores.onTertiaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sugerencia.texto),
              if (nivelNuevo != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colores.onTertiaryContainer,
                    minimumSize: TarjetaEjercicio._tamanoTactil,
                  ),
                  onPressed: () => viewModel.elegirNivel(ejercicio, nivelNuevo),
                  child: Text('Subir al nivel $nivelNuevo'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesHechas extends StatelessWidget {
  const _SeriesHechas({required this.viewModel, required this.ejercicio});

  final FuerzaViewModel viewModel;
  final Ejercicio ejercicio;

  @override
  Widget build(BuildContext context) {
    final hechas = viewModel.repeticionesHechas(ejercicio);
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var indice = 0; indice < hechas.length; indice++)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Serie ${indice + 1}: ${hechas[indice]}'),
                ),
            ],
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: TarjetaEjercicio._tamanoTactil),
          onPressed: () => viewModel.deshacerUltimaSerie(ejercicio),
          child: const Text('Deshacer'),
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.viewModel, required this.ejercicio, required this.serieActual});

  final FuerzaViewModel viewModel;
  final Ejercicio ejercicio;
  final int serieActual;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final marca = viewModel.marcaDe(ejercicio);
    final paso = viewModel.pasoDe(ejercicio);
    final magnitud = ejercicio.esTiempo ? 'segundos' : 'repeticiones';
    final unidad = '$magnitud${ejercicio.porLado ? ' por lado' : ''}';
    final estiloBoton = IconButton.styleFrom(minimumSize: TarjetaEjercicio._tamanoTactil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serie $serieActual de ${viewModel.seriesDe(ejercicio)}',
          style: tema.textTheme.titleSmall,
        ),
        Text(
          unidad,
          style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: ejercicio.esTiempo ? 'Restar $paso segundos' : 'Una repetición menos',
              style: estiloBoton,
              icon: const Icon(Icons.remove),
              onPressed: () => viewModel.restarMarca(ejercicio),
            ),
            SizedBox(
              width: 56,
              child: Semantics(
                label: '$marca $magnitud',
                excludeSemantics: true,
                child: Text(
                  '$marca',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.headlineMedium,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: ejercicio.esTiempo ? 'Sumar $paso segundos' : 'Una repetición más',
              style: estiloBoton,
              icon: const Icon(Icons.add),
              onPressed: () => viewModel.sumarMarca(ejercicio),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: TarjetaEjercicio._tamanoTactil),
                  icon: const Icon(Icons.check),
                  label: const Text('Hecha'),
                  onPressed: () => viewModel.completarSerie(ejercicio),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
