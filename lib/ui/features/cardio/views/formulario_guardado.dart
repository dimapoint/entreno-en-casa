import 'package:flutter/material.dart';

typedef DatosDeGuardado = ({int sensacion, String notas});

/// Hoja que pide "cómo te sentiste" y notas. Devuelve null si se cancela.
class FormularioGuardado extends StatefulWidget {
  const FormularioGuardado({super.key, required this.minutos});

  final int minutos;

  @override
  State<FormularioGuardado> createState() => _EstadoFormularioGuardado();
}

class _EstadoFormularioGuardado extends State<FormularioGuardado> {
  final _notas = TextEditingController();
  double _sensacion = 7;

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text('Guardar la sesión', style: estilos.titleLarge),
          Text(
            'Vas a guardar ${widget.minutos} min.',
            style: estilos.bodyLarge,
          ),
          Text('¿Cómo te sentiste?', style: estilos.titleMedium),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _sensacion,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${_sensacion.round()}',
                  semanticFormatterCallback: (valor) =>
                      '${valor.round()} de 10',
                  onChanged: (valor) => setState(() => _sensacion = valor),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${_sensacion.round()}',
                  textAlign: TextAlign.center,
                  style: estilos.headlineSmall?.copyWith(
                    color: esquema.primary,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 · muy mal', style: estilos.bodySmall),
              Text('10 · excelente', style: estilos.bodySmall),
            ],
          ),
          TextField(
            controller: _notas,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () =>
                Navigator.of(context)
                    .pop((sensacion: _sensacion.round(), notas: _notas.text)),
            child: const Text('Guardar'),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
