import 'package:flutter/material.dart';

typedef CierreDeSesion = ({int sensacion, String notas});

Future<CierreDeSesion?> pedirCierreDeSesion(BuildContext context) =>
    showModalBottomSheet<CierreDeSesion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _HojaTerminarSesion(),
    );

class _HojaTerminarSesion extends StatefulWidget {
  const _HojaTerminarSesion();

  @override
  State<_HojaTerminarSesion> createState() => _EstadoHojaTerminarSesion();
}

class _EstadoHojaTerminarSesion extends State<_HojaTerminarSesion> {
  final _notas = TextEditingController();
  int? _sensacion;

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sensacion = _sensacion;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text('¿Cómo te sentiste?', style: tema.textTheme.titleLarge),
          Text(
            '1 es muy mal y 10 es excelente.',
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var valor = 1; valor <= 10; valor++)
                ChoiceChip(
                  showCheckmark: false,
                  label: Text('$valor'),
                  selected: sensacion == valor,
                  onSelected: (_) => setState(() => _sensacion = valor),
                ),
            ],
          ),
          TextField(
            controller: _notas,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: sensacion == null
                ? null
                : () =>
                      Navigator.of(context)
                          .pop((sensacion: sensacion, notas: _notas.text)),
            child: const Text('Guardar sesión'),
          ),
        ],
      ),
    );
  }
}
