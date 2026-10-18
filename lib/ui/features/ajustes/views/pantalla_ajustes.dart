import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../core/formato.dart';
import '../view_models/ajustes_view_model.dart';

const _tamanoMinimoDeBoton = Size(64, 48);

class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _EstadoPantallaAjustes();
}

class _EstadoPantallaAjustes extends State<PantallaAjustes> {
  late final AjustesViewModel _viewModel;
  late final TextEditingController _codigo;
  bool _codigoVisible = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AjustesViewModel(
      repositorio: context.read<RepositorioEntrenamiento>(),
    );
    _codigo = TextEditingController(text: _viewModel.codigoGuardado);
  }

  @override
  void dispose() {
    _codigo.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _elegirFechaDeInicio() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _viewModel.fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Elegí cuándo arrancás',
    );
    if (elegida != null) await _viewModel.guardarFechaDeInicio(elegida);
  }

  Future<void> _guardarCodigo() =>
      _aplicarCodigo(_codigo.text, 'Código guardado');

  Future<void> _quitarCodigo() {
    _codigo.clear();
    setState(() => _codigoVisible = false);
    return _aplicarCodigo('', 'Código quitado');
  }

  Future<void> _aplicarCodigo(String codigo, String mensaje) async {
    final mensajero = ScaffoldMessenger.of(context);
    await _viewModel.guardarCodigo(codigo);
    mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes')),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _SeccionFechaDeInicio(
              viewModel: _viewModel,
              alElegir: _elegirFechaDeInicio,
            ),
            _SeccionSincronizacion(
              viewModel: _viewModel,
              codigo: _codigo,
              codigoVisible: _codigoVisible,
              alAlternarVisibilidad: () =>
                  setState(() => _codigoVisible = !_codigoVisible),
              alGuardar: _guardarCodigo,
              alQuitar: _quitarCodigo,
            ),
            const _SeccionAcercaDe(),
          ],
        ),
      ),
    ),
  );
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          ...hijos,
        ],
      ),
    ),
  );
}

class _SeccionFechaDeInicio extends StatelessWidget {
  const _SeccionFechaDeInicio({
    required this.viewModel,
    required this.alElegir,
  });

  final AjustesViewModel viewModel;
  final VoidCallback alElegir;

  @override
  Widget build(BuildContext context) {
    final fecha = viewModel.fechaInicio;
    final lunes = viewModel.lunesDeInicio;
    return _Seccion(
      titulo: 'Fecha de inicio',
      hijos: [
        Text(
          fecha == null
              ? 'Todavía no elegiste una fecha.'
              : conPrimeraMayuscula(fechaLarga(fecha)),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          lunes == null
              ? 'La semana 1 arranca el lunes de la semana que elijas.'
              : 'La semana 1 arranca el lunes de esa semana: ${fechaLarga(lunes)}.',
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: _tamanoMinimoDeBoton),
          onPressed: alElegir,
          icon: const Icon(Icons.event),
          label: Text(fecha == null ? 'Elegir fecha' : 'Cambiar fecha'),
        ),
      ],
    );
  }
}

class _SeccionSincronizacion extends StatelessWidget {
  const _SeccionSincronizacion({
    required this.viewModel,
    required this.codigo,
    required this.codigoVisible,
    required this.alAlternarVisibilidad,
    required this.alGuardar,
    required this.alQuitar,
  });

  final AjustesViewModel viewModel;
  final TextEditingController codigo;
  final bool codigoVisible;
  final VoidCallback alAlternarVisibilidad;
  final VoidCallback alGuardar;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sincronizando = viewModel.estadoSync == EstadoSync.sincronizando;
    return _Seccion(
      titulo: 'Sincronización',
      hijos: [
        const Text(
          'Usá el mismo código en la web y en el celular para ver lo mismo en los dos. Sin código, todo queda solo en este dispositivo.',
        ),
        if (!viewModel.sincronizacionDisponible)
          Text(
            'Esta versión no tiene un servidor configurado, así que por ahora no se puede sincronizar.',
            style: TextStyle(color: tema.colorScheme.error),
          ),
        TextField(
          controller: codigo,
          obscureText: !codigoVisible,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Código de sincronización',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: codigoVisible ? 'Ocultar código' : 'Mostrar código',
              onPressed: alAlternarVisibilidad,
              icon: Icon(
                codigoVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: codigo,
                builder: (context, _) => FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: _tamanoMinimoDeBoton,
                  ),
                  onPressed: codigo.text.trim().isEmpty ? null : alGuardar,
                  child: const Text('Guardar'),
                ),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: _tamanoMinimoDeBoton,
                ),
                onPressed: viewModel.hayCodigo ? alQuitar : null,
                child: const Text('Quitar código'),
              ),
            ),
          ],
        ),
        const Divider(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Icon(
              switch (viewModel.estadoSync) {
                EstadoSync.inactivo => Icons.cloud_off_outlined,
                EstadoSync.sincronizando => Icons.sync,
                EstadoSync.ok => Icons.cloud_done_outlined,
                EstadoSync.error => Icons.error_outline,
              },
              color: viewModel.estadoSync == EstadoSync.error
                  ? tema.colorScheme.error
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    viewModel.textoDeEstado,
                    style: tema.textTheme.titleSmall,
                  ),
                  if (viewModel.mensajeSync case final mensaje?) Text(mensaje),
                  Text(viewModel.textoDeUltimaSync),
                  Text(viewModel.textoDePendientes),
                ],
              ),
            ),
          ],
        ),
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(minimumSize: _tamanoMinimoDeBoton),
          onPressed: viewModel.puedeSincronizar
              ? viewModel.sincronizarAhora
              : null,
          icon: sincronizando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Sincronizando',
                  ),
                )
              : const Icon(Icons.sync),
          label: const Text('Sincronizar ahora'),
        ),
      ],
    );
  }
}

class _SeccionAcercaDe extends StatelessWidget {
  const _SeccionAcercaDe();

  @override
  Widget build(BuildContext context) => const _Seccion(
    titulo: 'Acerca de',
    hijos: [
      Text('Entreno en casa: plan de entrenamiento en casa de 13 semanas.'),
    ],
  );
}
