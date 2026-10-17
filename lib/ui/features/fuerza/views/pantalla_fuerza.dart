import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/models/ejercicio.dart';
import '../../../../domain/plan/plan_casa.dart';
import '../view_models/fuerza_view_model.dart';
import 'widgets/barra_descanso.dart';
import 'widgets/hoja_terminar_sesion.dart';
import 'widgets/seccion_tildable.dart';
import 'widgets/tarjeta_ejercicio.dart';

class PantallaFuerza extends StatefulWidget {
  const PantallaFuerza({super.key, required this.rutina, required this.semana});

  final Rutina rutina;

  /// Semana absoluta del plan (puede pasar de 13).
  final int semana;

  @override
  State<PantallaFuerza> createState() => _EstadoPantallaFuerza();
}

class _EstadoPantallaFuerza extends State<PantallaFuerza> {
  late final FuerzaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FuerzaViewModel(
      repositorio: context.read<RepositorioEntrenamiento>(),
      rutina: widget.rutina,
      semana: widget.semana,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text(
          'Las series que cargaste se pierden si salís ahora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Seguir entrenando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (salir == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _terminar() async {
    final mensajero = ScaffoldMessenger.of(context);
    if (!_viewModel.puedeGuardar) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('Marcá al menos una serie para guardar la sesión.'),
        ),
      );
      return;
    }
    final cierre = await pedirCierreDeSesion(context);
    if (cierre == null) return;
    try {
      final guardada = await _viewModel.guardarSesion(
        sensacion: cierre.sensacion,
        notas: cierre.notas,
      );
      if (!guardada) return;
    } on Object {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la sesión. Probá de nuevo.'),
        ),
      );
      return;
    }
    mensajero.showSnackBar(const SnackBar(content: Text('Sesión guardada.')));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (contexto, _) {
      final descanso = _viewModel.descanso;
      return PopScope(
        canPop: !_viewModel.haySinGuardar,
        onPopInvokedWithResult: (seSalio, _) {
          if (!seSalio) unawaited(_confirmarSalida());
        },
        child: Scaffold(
          appBar: AppBar(title: Text('Fuerza ${widget.rutina.letra}')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                _Encabezado(viewModel: _viewModel),
                _TarjetaDiaFlojo(viewModel: _viewModel),
                if (_viewModel.consejoVisible)
                  _TarjetaConsejo(viewModel: _viewModel),
                SeccionTildable(
                  key: const ValueKey('calentamiento'),
                  titulo: 'Calentamiento (8–10 min)',
                  lista: _viewModel.calentamiento,
                  alAlternar: (indice) =>
                      _viewModel.alternarItem(_viewModel.calentamiento, indice),
                ),
                for (final ejercicio in _viewModel.ejercicios)
                  TarjetaEjercicio(
                    key: ValueKey(ejercicio.id),
                    viewModel: _viewModel,
                    ejercicio: ejercicio,
                  ),
                SeccionTildable(
                  key: const ValueKey('vuelta_a_la_calma'),
                  titulo: 'Vuelta a la calma (5 min)',
                  nota: PlanCasa.notaVueltaALaCalma,
                  lista: _viewModel.vueltaALaCalma,
                  alAlternar: (indice) => _viewModel.alternarItem(
                    _viewModel.vueltaALaCalma,
                    indice,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Material(
            elevation: 3,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (descanso != null)
                    BarraDescanso(
                      controlador: descanso,
                      alAgregarTiempo: _viewModel.agregarTiempoDeDescanso,
                      alCerrar: _viewModel.cerrarDescanso,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _terminar,
                      child: const Text('Terminar sesión'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.viewModel});

  final FuerzaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          'Semana ${viewModel.semana} · ${viewModel.plan.fase.etiqueta}',
          style: tema.textTheme.headlineSmall,
        ),
        if (viewModel.esCicloRepetido)
          Text(
            'Ciclo repetido: esta semana toca como la ${viewModel.semanaEfectiva}.',
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(viewModel.plan.fuerzaTexto, style: tema.textTheme.bodyLarge),
      ],
    );
  }
}

class _TarjetaDiaFlojo extends StatelessWidget {
  const _TarjetaDiaFlojo({required this.viewModel});

  final FuerzaViewModel viewModel;

  @override
  Widget build(BuildContext context) => Card(
    child: SwitchListTile(
      title: const Text('Día flojo'),
      subtitle: const Text(
        '2 series por ejercicio y sin intentar subir repeticiones.',
      ),
      value: viewModel.diaFlojo,
      onChanged: (activo) => viewModel.cambiarDiaFlojo(activo: activo),
    ),
  );
}

class _TarjetaConsejo extends StatelessWidget {
  const _TarjetaConsejo({required this.viewModel});

  final FuerzaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Card(
      color: colores.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(
                Icons.lightbulb_outline,
                color: colores.onSecondaryContainer,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  viewModel.consejo,
                  style: TextStyle(color: colores.onSecondaryContainer),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Descartar consejo',
              color: colores.onSecondaryContainer,
              icon: const Icon(Icons.close),
              onPressed: viewModel.descartarConsejo,
            ),
          ],
        ),
      ),
    );
  }
}
