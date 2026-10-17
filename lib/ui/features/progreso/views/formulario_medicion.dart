import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../view_models/campo_medicion.dart';
import '../view_models/progreso_view_model.dart';

Future<void> abrirFormularioMedicion(
  BuildContext context,
  ProgresoViewModel viewModel,
  MomentoMedicion momento,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  enableDrag: false,
  builder: (_) => FormularioMedicion(viewModel: viewModel, momento: momento),
);

class FormularioMedicion extends StatefulWidget {
  const FormularioMedicion({
    super.key,
    required this.viewModel,
    required this.momento,
  });

  final ProgresoViewModel viewModel;
  final MomentoMedicion momento;

  @override
  State<FormularioMedicion> createState() => _EstadoFormularioMedicion();
}

class _EstadoFormularioMedicion extends State<FormularioMedicion> {
  final _clave = GlobalKey<FormState>();
  late final Map<CampoMedicion, TextEditingController> _controladores;
  int? _nivelFlexiones;
  String? _error;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _controladores = {
      for (final campo in CampoMedicion.values)
        campo: TextEditingController(
          text: switch (widget.momento.valor(campo)) {
            final cargado? => textoNumero(cargado),
            null => '',
          },
        ),
    };
    _nivelFlexiones = widget.momento.medicion?.flexionesNivel;
  }

  @override
  void dispose() {
    for (final controlador in _controladores.values) {
      controlador.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final guardado = await widget.viewModel.guardarMedicion(
      semana: widget.momento.semana,
      textos: {
        for (final entrada in _controladores.entries)
          entrada.key: entrada.value.text,
      },
      nivelFlexiones: _nivelFlexiones,
    );
    if (!mounted) return;
    if (guardado) {
      Navigator.pop(context);
    } else {
      setState(() {
        _guardando = false;
        _error = 'Cargá al menos un valor para poder guardar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _clave,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.momento.titulo, style: tema.textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final entrada in _controladores.entries) ...[
              _CampoNumerico(campo: entrada.key, controlador: entrada.value),
              if (entrada.key == CampoMedicion.flexiones)
                _SelectorDeNivel(
                  niveles: widget.viewModel.nivelesDeFlexiones,
                  seleccionado: _nivelFlexiones,
                  alCambiar: (nivel) => setState(() => _nivelFlexiones = nivel),
                ),
              const SizedBox(height: 12),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: tema.colorScheme.error),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoNumerico extends StatelessWidget {
  const _CampoNumerico({required this.campo, required this.controlador});

  final CampoMedicion campo;
  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controlador,
    keyboardType: TextInputType.numberWithOptions(decimal: campo.decimal),
    textInputAction: TextInputAction.next,
    inputFormatters: [
      campo.decimal
          ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          : FilteringTextInputFormatter.digitsOnly,
    ],
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: campo.validar,
    decoration: InputDecoration(
      labelText: '${campo.etiqueta} (${campo.unidad})',
      helperText: campo.ayuda,
      border: const OutlineInputBorder(),
    ),
  );
}

class _SelectorDeNivel extends StatelessWidget {
  const _SelectorDeNivel({
    required this.niveles,
    required this.seleccionado,
    required this.alCambiar,
  });

  final List<String> niveles;
  final int? seleccionado;
  final ValueChanged<int?> alCambiar;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nivel de las flexiones (opcional)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              for (var nivel = 1; nivel <= niveles.length; nivel++)
                ButtonSegment(value: nivel, label: Text('Nivel $nivel')),
            ],
            selected: {?seleccionado},
            onSelectionChanged: (seleccion) => alCambiar(seleccion.firstOrNull),
          ),
          const SizedBox(height: 4),
          Text(
            niveles.indexed
                .map((par) => 'Nivel ${par.$1 + 1}: ${par.$2.toLowerCase()}')
                .join('. '),
            style: estilo,
          ),
        ],
      ),
    );
  }
}
