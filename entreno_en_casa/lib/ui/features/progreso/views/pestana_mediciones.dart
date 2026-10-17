import 'package:flutter/material.dart';

import '../../../core/formato.dart';
import '../view_models/campo_medicion.dart';
import '../view_models/progreso_view_model.dart';
import 'formulario_medicion.dart';

class PestanaMediciones extends StatelessWidget {
  const PestanaMediciones({super.key, required this.viewModel});

  final ProgresoViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _InstruccionesDeMedicion(),
            const SizedBox(height: 16),
            for (final momento in viewModel.momentos) ...[
              _TarjetaMomento(
                momento: momento,
                alTocar: () => abrirFormularioMedicion(context, viewModel, momento),
              ),
              const SizedBox(height: 12),
            ],
            const _SenalesDeProgreso(),
          ],
        ),
      );
}

class _Vineta extends StatelessWidget {
  const _Vineta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(child: Text('•  ')),
            Expanded(child: Text(texto)),
          ],
        ),
      );
}

class _InstruccionesDeMedicion extends StatelessWidget {
  const _InstruccionesDeMedicion();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cómo medir', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('La balanza sola engaña: la cintura y las pruebas pesan más.'),
              const _Vineta(
                'Medís el día 0 y las semanas 4, 8 y 13, siempre a la mañana, en ayunas, '
                'después de ir al baño.',
              ),
              const _Vineta('Peso: pesate 3 veces esa semana y anotá el promedio.'),
              const _Vineta(
                'Cintura: cinta métrica a la altura del ombligo, sin apretar, al final de exhalar.',
              ),
              const _Vineta(
                'Fotos: de frente, de perfil y de espalda, con la misma luz, la misma ropa y la '
                'misma distancia. Las fotos no se guardan en la app: sacalas y guardalas en tu celular.',
              ),
            ],
          ),
        ),
      );
}

class _SenalesDeProgreso extends StatelessWidget {
  const _SenalesDeProgreso();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Señales de que va bien', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'La cintura baja o se mantiene con el mismo peso, hacés más repeticiones o pasás '
                'de nivel, y el cardio suave se siente más fácil al mismo ritmo.',
              ),
            ],
          ),
        ),
      );
}

class _TarjetaMomento extends StatelessWidget {
  const _TarjetaMomento({required this.momento, required this.alTocar});

  final MomentoMedicion momento;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final medicion = momento.medicion;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: momento.pendiente
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: tema.colorScheme.primary, width: 2),
            )
          : null,
      child: Semantics(
        button: true,
        hint: medicion == null ? 'Tocá para cargar las medidas' : 'Tocá para editar las medidas',
        child: InkWell(
          onTap: alTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(momento.titulo, style: tema.textTheme.titleMedium),
                          if (momento.pendiente)
                            Text(
                              'Toca medir esta semana',
                              style: tema.textTheme.labelLarge?.copyWith(
                                color: tema.colorScheme.primary,
                              ),
                            )
                          else
                            Text(
                              medicion == null
                                  ? 'Sin cargar'
                                  : 'Medido el ${fechaCorta(medicion.fecha)}',
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        medicion == null ? Icons.add_circle_outline : Icons.edit_outlined,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final campo in CampoMedicion.values)
                  _FilaDeMedida(momento: momento, campo: campo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaDeMedida extends StatelessWidget {
  const _FilaDeMedida({required this.momento, required this.campo});

  final MomentoMedicion momento;
  final CampoMedicion campo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final diferencia = momento.diferencia(campo);
    final cargado = momento.valor(campo) != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(campo.etiqueta, style: tema.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  momento.textoDe(campo),
                  semanticsLabel: cargado ? null : 'Sin cargar',
                  textAlign: TextAlign.end,
                  style: tema.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (diferencia != null)
                  Text(
                    diferencia.texto,
                    textAlign: TextAlign.end,
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: diferencia.buenaSenal
                          ? tema.colorScheme.primary
                          : tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
