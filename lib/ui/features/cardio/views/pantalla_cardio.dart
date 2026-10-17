import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/models/registro_sesion.dart';
import '../../../core/formato.dart';
import '../../../core/temporizador_fases.dart';
import '../view_models/cardio_view_model.dart';
import 'formulario_guardado.dart';

class PantallaCardio extends StatefulWidget {
  const PantallaCardio({super.key, required this.tipo, required this.semana, this.minutos});

  /// cardioSuave, intervalos o descansoActivo.
  final TipoSesion tipo;

  /// Semana absoluta del plan (puede pasar de 13).
  final int semana;

  /// Duración planificada para cardio suave. Si es nulo, se toma la del plan para el día de hoy.
  final int? minutos;

  @override
  State<PantallaCardio> createState() => _EstadoPantallaCardio();
}

class _EstadoPantallaCardio extends State<PantallaCardio> {
  late final CardioViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CardioViewModel(
      repositorio: context.read<RepositorioEntrenamiento>(),
      tipo: widget.tipo,
      semana: widget.semana,
      minutos: widget.minutos,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Se frena el reloj para que los minutos no sigan corriendo mientras se completa el formulario.
    _viewModel.controlador.pausar();
    final datos = await showModalBottomSheet<DatosDeGuardado>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FormularioGuardado(minutos: _viewModel.duracionRealMinutos),
    );
    if (datos == null) return;
    final guardada = await _viewModel.guardar(sensacion: datos.sensacion, notas: datos.notas);
    if (guardada && mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Si salís ahora, perdés lo que llevás de esta sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Seguir acá'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (salir == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final controlador = _viewModel.controlador;
          final aviso = _viewModel.aviso;
          return PopScope(
            canPop: !_viewModel.puedeGuardar,
            onPopInvokedWithResult: (salio, _) {
              if (!salio) unawaited(_confirmarSalida());
            },
            child: Scaffold(
              appBar: AppBar(title: Text(widget.tipo.etiqueta)),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      if (aviso != null) _Aviso(texto: aviso),
                      _TarjetaTemporizador(controlador: controlador),
                      _Controles(viewModel: _viewModel, alGuardar: _guardar),
                      if (controlador.estado == EstadoTemporizador.quieto)
                        _VistaPrevia(viewModel: _viewModel),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      color: esquema.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Icon(Icons.info_outline, color: esquema.onTertiaryContainer),
            Expanded(
              child: Text(texto, style: TextStyle(color: esquema.onTertiaryContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaTemporizador extends StatelessWidget {
  const _TarjetaTemporizador({required this.controlador});

  final ControladorFases controlador;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final fase = controlador.faseActual;
    final estado = controlador.estado;
    final terminado = estado == EstadoTemporizador.terminado;
    final indiceSiguiente = controlador.indiceActual + 1;
    final siguiente = indiceSiguiente < controlador.fases.length
        ? controlador.fases[indiceSiguiente]
        : null;
    final detalle = terminado
        ? 'Guardá la sesión para que quede en tu progreso.'
        : fase.detalle;
    const cifrasFijas = [FontFeature.tabularFigures()];

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              switch (estado) {
                EstadoTemporizador.quieto => 'Listo para arrancar',
                EstadoTemporizador.corriendo => 'En marcha',
                EstadoTemporizador.pausado => 'En pausa',
                EstadoTemporizador.terminado => 'Sesión completa',
              },
              textAlign: TextAlign.center,
              style: estilos.labelLarge?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              terminado ? '¡Terminaste!' : fase.titulo,
              textAlign: TextAlign.center,
              style: estilos.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                minutosYSegundos(controlador.segundosRestantes),
                style: estilos.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: cifrasFijas,
                  color: fase.esDescanso && !terminado ? esquema.tertiary : esquema.primary,
                ),
              ),
            ),
            if (detalle != null)
              Text(detalle, textAlign: TextAlign.center, style: estilos.bodyLarge),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: controlador.progresoTotal,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              semanticsLabel: 'Progreso de la sesión',
            ),
            const SizedBox(height: 8),
            Row(
              spacing: 12,
              children: [
                Expanded(child: Text('Tiempo total restante', style: estilos.bodyMedium)),
                Text(
                  minutosYSegundos(controlador.segundosRestantesTotal),
                  style: estilos.titleMedium?.copyWith(fontFeatures: cifrasFijas),
                ),
              ],
            ),
            if (siguiente != null && !terminado) ...[
              const Divider(height: 24),
              Text(
                'Sigue: ${siguiente.titulo} (${minutosYSegundos(siguiente.segundos)})',
                textAlign: TextAlign.center,
                style: estilos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Controles extends StatelessWidget {
  const _Controles({required this.viewModel, required this.alGuardar});

  final CardioViewModel viewModel;
  final VoidCallback alGuardar;

  @override
  Widget build(BuildContext context) {
    final controlador = viewModel.controlador;
    final estado = controlador.estado;
    final terminado = estado == EstadoTemporizador.terminado;
    final quieto = estado == EstadoTemporizador.quieto;
    final enMarcha = estado == EstadoTemporizador.corriendo;
    final estiloPrincipal = FilledButton.styleFrom(minimumSize: const Size.fromHeight(56));
    final estiloSecundario = OutlinedButton.styleFrom(minimumSize: const Size(0, 48));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (terminado)
          FilledButton.icon(
            style: estiloPrincipal,
            onPressed: alGuardar,
            icon: const Icon(Icons.check),
            label: const Text('Guardar'),
          )
        else
          FilledButton.icon(
            style: estiloPrincipal,
            // iniciar() también reanuda una pausa.
            onPressed: enMarcha ? controlador.pausar : controlador.iniciar,
            icon: Icon(enMarcha ? Icons.pause : Icons.play_arrow),
            label: Text(
              switch (estado) {
                EstadoTemporizador.corriendo => 'Pausar',
                EstadoTemporizador.pausado => 'Reanudar',
                _ => 'Iniciar',
              },
            ),
          ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: estiloSecundario,
                onPressed: quieto || terminado ? null : controlador.saltarFase,
                icon: const Icon(Icons.skip_next),
                label: const Text('Saltar fase'),
              ),
            ),
            Expanded(
              child: OutlinedButton.icon(
                style: estiloSecundario,
                onPressed: quieto ? null : controlador.reiniciar,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar'),
              ),
            ),
          ],
        ),
        if (!terminado && viewModel.puedeGuardar)
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: alGuardar,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar lo hecho'),
          ),
      ],
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia({required this.viewModel});

  final CardioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final minutos = viewModel.controlador.duracionTotalSegundos ~/ 60;
    final opciones = viewModel.opciones;
    final pasos = viewModel.pasosDeMovilidad;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (viewModel.permiteDesdeCero)
          Card(
            child: SwitchListTile(
              title: const Text('Estoy arrancando a trotar desde cero'),
              subtitle: const Text('Alternás trote y caminata según tu semana del plan.'),
              value: viewModel.desdeCero,
              onChanged: viewModel.cambiarDesdeCero,
            ),
          ),
        _Seccion(
          titulo: 'Así es la sesión ($minutos min)',
          hijos: [for (final linea in viewModel.estructura) _Punto(texto: linea)],
        ),
        if (pasos.isNotEmpty)
          _Seccion(
            titulo: 'Movilidad, paso a paso',
            hijos: [for (final paso in pasos) _Punto(texto: paso)],
          ),
        if (opciones.isNotEmpty)
          _Seccion(
            titulo: 'Opciones para el cardio suave',
            hijos: [
              for (final opcion in opciones) _Punto(destacado: opcion.titulo, texto: opcion.texto),
            ],
          ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
              ...hijos,
            ],
          ),
        ),
      );
}

class _Punto extends StatelessWidget {
  const _Punto({required this.texto, this.destacado});

  final String texto;
  final String? destacado;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Text('•'),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (destacado != null)
                    TextSpan(
                      text: '$destacado: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  TextSpan(text: texto),
                ],
              ),
            ),
          ),
        ],
      );
}
