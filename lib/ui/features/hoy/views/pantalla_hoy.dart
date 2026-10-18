import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/models/ejercicio.dart';
import '../../../../domain/models/registro_sesion.dart';
import '../../../core/formato.dart';
import '../../cardio/views/pantalla_cardio.dart';
import '../../fuerza/views/pantalla_fuerza.dart';
import '../view_models/hoy_view_model.dart';

const _tamanoMinimoDeBoton = Size(64, 48);

const _preparativos = [
  'Hacé las mediciones del día 0.',
  'Prepará el espacio: unos 2 × 2 m libres, con piso liso para el curl femoral con toalla.',
  'Probá que la mesa del remo invertido aguante tu peso.',
];
const _indicePreparativoDeMediciones = 0;

class PantallaHoy extends StatefulWidget {
  /// [ahora] solo se pasa en las pruebas, para fijar el día.
  const PantallaHoy({super.key, required this.irAProgreso, this.ahora});

  final VoidCallback irAProgreso;
  final DateTime Function()? ahora;

  @override
  State<PantallaHoy> createState() => _EstadoPantallaHoy();
}

class _EstadoPantallaHoy extends State<PantallaHoy>
    with WidgetsBindingObserver {
  late final HoyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HoyViewModel(
      repositorio: context.read<RepositorioEntrenamiento>(),
      ahora: widget.ahora,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _viewModel.refrescar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _elegirOtraFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _viewModel.proximoLunes,
      firstDate: DateTime(_viewModel.hoy.year - 1),
      lastDate: DateTime(_viewModel.hoy.year + 1, 12, 31),
      helpText: 'Elegí cuándo arrancás',
    );
    if (elegida != null) await _viewModel.elegirFechaDeInicio(elegida);
  }

  void _empezar(TipoSesion tipo) {
    final semana = _viewModel.semana;
    final Widget pantalla = tipo.esFuerza
        ? PantallaFuerza(
            rutina: tipo == TipoSesion.fuerzaA ? Rutina.a : Rutina.b,
            semana: semana,
          )
        : PantallaCardio(
            tipo: tipo,
            semana: semana,
            minutos: tipo == TipoSesion.cardioSuave
                ? _viewModel.minutosDeCardioSuave
                : null,
          );
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hoy')),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: switch (_viewModel.etapa) {
            EtapaHoy.sinFechaDeInicio => [
              _TarjetaBienvenida(
                viewModel: _viewModel,
                alElegirOtraFecha: _elegirOtraFecha,
              ),
            ],
            EtapaHoy.antesDeEmpezar => [
              _TarjetaAntesDeEmpezar(
                viewModel: _viewModel,
                irAProgreso: widget.irAProgreso,
              ),
            ],
            EtapaHoy.enCurso => [
              _EncabezadoDeLaSemana(viewModel: _viewModel),
              if (_viewModel.medicionPendiente case final momento?)
                _TarjetaMedicion(
                  momento: momento,
                  irAProgreso: widget.irAProgreso,
                ),
              _TarjetaDeHoy(viewModel: _viewModel, alEmpezar: _empezar),
              _TiraDeLaSemana(dias: _viewModel.dias),
              if (!_viewModel.cicloRepetido)
                if (_viewModel.plan.hito case final hito?)
                  _TarjetaHito(hito: hito),
              _MenuOtraSesion(alElegir: _empezar),
              const _NotaSemanaComplicada(),
            ],
          },
        ),
      ),
    ),
  );
}

class _TarjetaBienvenida extends StatelessWidget {
  const _TarjetaBienvenida({
    required this.viewModel,
    required this.alElegirOtraFecha,
  });

  final HoyViewModel viewModel;
  final VoidCallback alElegirOtraFecha;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text('Entreno en casa', style: textos.headlineSmall),
            const Text(
              'En 13 semanas buscás bajar grasa, ganar músculo y aguantar más, entrenando en casa 5 días por semana. Las primeras 4 semanas son suaves a propósito.',
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: _tamanoMinimoDeBoton),
              onPressed: viewModel.arrancarElProximoLunes,
              child: Text('Arrancar el ${fechaLarga(viewModel.proximoLunes)}'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: _tamanoMinimoDeBoton,
              ),
              onPressed: alElegirOtraFecha,
              child: const Text('Elegir otra fecha'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAntesDeEmpezar extends StatelessWidget {
  const _TarjetaAntesDeEmpezar({
    required this.viewModel,
    required this.irAProgreso,
  });

  final HoyViewModel viewModel;
  final VoidCallback irAProgreso;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(viewModel.cuentaRegresiva, style: textos.headlineSmall),
            Text(
              'Arrancás el ${fechaLarga(viewModel.lunesDeInicio)}. Podés cambiar la fecha en Ajustes.',
            ),
            const SizedBox(height: 8),
            Text('Antes del primer entrenamiento', style: textos.titleMedium),
            for (var indice = 0; indice < _preparativos.length; indice++) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: viewModel.preparativoHecho(indice),
                onChanged: (_) => viewModel.alternarPreparativo(indice),
                title: Text(_preparativos[indice]),
              ),
              if (indice == _indicePreparativoDeMediciones)
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: _tamanoMinimoDeBoton,
                    ),
                    onPressed: irAProgreso,
                    child: const Text('Ir a Progreso'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EncabezadoDeLaSemana extends StatelessWidget {
  const _EncabezadoDeLaSemana({required this.viewModel});

  final HoyViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final plan = viewModel.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          conPrimeraMayuscula(fechaLarga(viewModel.hoy)),
          style: tema.textTheme.labelLarge?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(viewModel.tituloDeLaSemana, style: tema.textTheme.headlineSmall),
        if (viewModel.cicloRepetido)
          Text('Ciclo repetido: semana efectiva ${viewModel.semanaEfectiva}'),
        Text(
          'Fase ${plan.fase.etiqueta.toLowerCase()}',
          style: tema.textTheme.titleSmall,
        ),
        Text('Fuerza: ${plan.fuerzaTexto}'),
      ],
    );
  }
}

class _TarjetaMedicion extends StatelessWidget {
  const _TarjetaMedicion({required this.momento, required this.irAProgreso});

  final int momento;
  final VoidCallback irAProgreso;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final titulo = momento == 0
        ? 'Faltan las mediciones del día 0'
        : 'Toca medirte: semana $momento';
    return Card.filled(
      color: tema.colorScheme.secondaryContainer,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: tema.colorScheme.onSecondaryContainer),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(titulo, style: tema.textTheme.titleMedium),
              const Text('Con las mediciones vas a ver cuánto avanzaste.'),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: _tamanoMinimoDeBoton,
                ),
                onPressed: irAProgreso,
                child: const Text('Ir a Progreso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaDeHoy extends StatelessWidget {
  const _TarjetaDeHoy({required this.viewModel, required this.alEmpezar});

  final HoyViewModel viewModel;
  final void Function(TipoSesion tipo) alEmpezar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tipo = viewModel.sesionDeHoy;
    if (tipo == null) {
      return Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('Descanso total', style: tema.textTheme.titleLarge),
              const Text(
                'Hoy no entrenás. Dormí bien y comé bien: el músculo se arma mientras descansás.',
              ),
            ],
          ),
        ),
      );
    }
    return Card.filled(
      color: tema.colorScheme.primaryContainer,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: tema.colorScheme.onPrimaryContainer),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text('Sesión de hoy', style: tema.textTheme.labelLarge),
              Text(tipo.etiqueta, style: tema.textTheme.headlineSmall),
              Text(
                'Duración: ${viewModel.duracionDeHoy}',
                style: tema.textTheme.titleSmall,
              ),
              Text(viewModel.detalleDeHoy!),
              if (viewModel.hizoSesionHoy)
                const Text(
                  'Hoy ya registraste una sesión. Si querés, podés hacer otra.',
                ),
              if (viewModel.avisarDescansoInsuficiente)
                const _AvisoDeDescanso(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: _tamanoMinimoDeBoton,
                ),
                onPressed: () => alEmpezar(tipo),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvisoDeDescanso extends StatelessWidget {
  const _AvisoDeDescanso();

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colores.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colores.onTertiaryContainer,
            ),
            Expanded(
              child: Text(
                'Pasaron menos de 48 h desde tu última sesión de fuerza. Si podés, dejá descansar un rato más al cuerpo antes de arrancar.',
                style: TextStyle(color: colores.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TiraDeLaSemana extends StatelessWidget {
  const _TiraDeLaSemana({required this.dias});

  final List<DiaDeLaSemana> dias;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          for (final dia in dias) Expanded(child: _CeldaDelDia(dia: dia)),
        ],
      ),
    ),
  );
}

class _CeldaDelDia extends StatelessWidget {
  const _CeldaDelDia({required this.dia});

  final DiaDeLaSemana dia;

  static String _abreviatura(TipoSesion? tipo) => switch (tipo) {
    null => 'Libre',
    TipoSesion.fuerzaA => 'A',
    TipoSesion.fuerzaB => 'B',
    TipoSesion.cardioSuave => 'Suave',
    TipoSesion.intervalos => 'Interv.',
    TipoSesion.descansoActivo => 'Activo',
  };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorDelTexto = dia.esHoy
        ? tema.colorScheme.onPrimaryContainer
        : null;
    final nombre = nombreDia(dia.fecha.weekday);
    return Semantics(
      excludeSemantics: true,
      label:
          '${conPrimeraMayuscula(nombre)}: ${dia.sesion?.etiqueta ?? 'descanso total'}'
          '${dia.registrada ? ', hecha' : ''}${dia.esHoy ? ', hoy' : ''}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dia.esHoy ? tema.colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            spacing: 4,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  conPrimeraMayuscula(nombre.substring(0, 3)),
                  style: tema.textTheme.labelLarge?.copyWith(
                    color: colorDelTexto,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _abreviatura(dia.sesion),
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: colorDelTexto,
                  ),
                ),
              ),
              dia.registrada
                  ? Icon(
                      Icons.check_circle,
                      size: 20,
                      color: tema.colorScheme.primary,
                    )
                  : const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaHito extends StatelessWidget {
  const _TarjetaHito({required this.hito});

  final String hito;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: ListTile(
      leading: const Icon(Icons.flag_outlined),
      title: const Text('Hito de la semana'),
      subtitle: Text(hito),
    ),
  );
}

class _MenuOtraSesion extends StatelessWidget {
  const _MenuOtraSesion({required this.alElegir});

  final void Function(TipoSesion tipo) alElegir;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      MenuAnchor(
        menuChildren: [
          for (final tipo in TipoSesion.values)
            MenuItemButton(
              onPressed: () => alElegir(tipo),
              child: Text(tipo.etiqueta),
            ),
        ],
        builder: (context, controlador, _) => OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: _tamanoMinimoDeBoton),
          onPressed: () =>
              controlador.isOpen ? controlador.close() : controlador.open(),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Hacer otra sesión'),
        ),
      ),
      Text(
        'Los días son orientativos: movelos según tu semana, respetando las 48 h entre sesiones de fuerza.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _NotaSemanaComplicada extends StatelessWidget {
  const _NotaSemanaComplicada();

  @override
  Widget build(BuildContext context) => Card.outlined(
    clipBehavior: Clip.antiAlias,
    child: const ExpansionTile(
      shape: Border(),
      collapsedShape: Border(),
      title: Text('¿Semana complicada?'),
      childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Si tenés parciales o una semana imposible, quedate con el mínimo: 2 sesiones de fuerza de 30 min, con 2 series por ejercicio, y caminá todo lo que puedas. Sostener el hábito pesa más que hacer la sesión perfecta.',
        ),
      ],
    ),
  );
}
