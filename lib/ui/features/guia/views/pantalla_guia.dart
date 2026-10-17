import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../../../../domain/plan/guia.dart';
import '../view_models/guia_view_model.dart';

const _iconos = <String, IconData>{
  'objetivo': Icons.flag_outlined,
  'semana': Icons.calendar_today_outlined,
  'calentamiento': Icons.self_improvement_outlined,
  'progresion': Icons.trending_up,
  'cardio': Icons.favorite_border,
  'semanas': Icons.event_note_outlined,
  'alimentacion': Icons.restaurant_outlined,
  'medicion': Icons.straighten,
  'alertas': Icons.warning_amber_outlined,
};

TextStyle? _estiloCuerpo(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4);

class PantallaGuia extends StatefulWidget {
  const PantallaGuia({super.key});

  @override
  State<PantallaGuia> createState() => _EstadoPantallaGuia();
}

class _EstadoPantallaGuia extends State<PantallaGuia> {
  late final GuiaViewModel _viewModel;
  final _controladorBusqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = GuiaViewModel(
      repositorio: context.read<RepositorioEntrenamiento>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _borrarBusqueda() {
    _controladorBusqueda.clear();
    _viewModel.buscar('');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guía')),
    body: SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AvisoMedico(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controladorBusqueda,
                onChanged: _viewModel.buscar,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Buscar en la guía',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _viewModel.buscando
                      ? IconButton(
                          tooltip: 'Borrar búsqueda',
                          icon: const Icon(Icons.close),
                          onPressed: _borrarBusqueda,
                        )
                      : null,
                ),
              ),
            ),
            Expanded(child: _ListaSecciones(viewModel: _viewModel)),
          ],
        ),
      ),
    ),
  );
}

class _AvisoMedico extends StatelessWidget {
  const _AvisoMedico();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      color: esquema.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 20,
            color: esquema.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'La app no reemplaza la consulta médica. Antes de arrancar, pedile el apto físico '
              'a un clínico.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: esquema.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaSecciones extends StatelessWidget {
  const _ListaSecciones({required this.viewModel});

  final GuiaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final secciones = viewModel.seccionesVisibles;
    // Sin lista perezosa a propósito: son pocas secciones y así cada una
    // conserva si estaba abierta o cerrada al hacer scroll.
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: secciones.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No encontramos nada para "${viewModel.consulta.trim()}". Probá con otra palabra.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                for (final seccion in secciones)
                  _SeccionVista(seccion: seccion, viewModel: viewModel),
              ],
            ),
    );
  }
}

class _SeccionVista extends StatelessWidget {
  const _SeccionVista({required this.seccion, required this.viewModel});

  final SeccionGuia seccion;
  final GuiaViewModel viewModel;

  @override
  Widget build(BuildContext context) => Card.outlined(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      // Al empezar o terminar una búsqueda se recrea para abrir o cerrar las secciones.
      key: ValueKey('${seccion.titulo}-${viewModel.buscando}'),
      initiallyExpanded: viewModel.buscando,
      leading: Icon(_iconos[seccion.icono]),
      title: Text(
        seccion.titulo,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            for (final bloque in seccion.bloques)
              _BloqueVista(bloque: bloque, viewModel: viewModel),
          ],
        ),
      ],
    ),
  );
}

class _BloqueVista extends StatelessWidget {
  const _BloqueVista({required this.bloque, required this.viewModel});

  final BloqueGuia bloque;
  final GuiaViewModel viewModel;

  @override
  Widget build(BuildContext context) => switch (bloque) {
    SubtituloGuia(:final texto) => Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(texto, style: Theme.of(context).textTheme.titleSmall),
      ),
    ),
    ParrafoGuia(:final texto, :final etiqueta) => _TextoConEtiqueta(
      texto: texto,
      etiqueta: etiqueta,
    ),
    NotaGuia(:final texto, :final etiqueta) => _Nota(
      texto: texto,
      etiqueta: etiqueta,
    ),
    final ListaGuia lista => _Lista(lista: lista),
    final TablaGuia tabla => _Tabla(tabla: tabla, viewModel: viewModel),
  };
}

class _TextoConEtiqueta extends StatelessWidget {
  const _TextoConEtiqueta({required this.texto, this.etiqueta, this.color});

  final String texto;
  final String? etiqueta;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: _estiloCuerpo(context)?.copyWith(color: color),
      children: [
        if (etiqueta != null)
          TextSpan(
            text: '$etiqueta: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        TextSpan(text: texto),
      ],
    ),
  );
}

class _Nota extends StatelessWidget {
  const _Nota({required this.texto, this.etiqueta});

  final String texto;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esquema.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _TextoConEtiqueta(
        texto: texto,
        etiqueta: etiqueta,
        color: esquema.onTertiaryContainer,
      ),
    );
  }
}

class _FilaConMarcador extends StatelessWidget {
  const _FilaConMarcador({required this.marcador, required this.hijo});

  final String marcador;
  final Widget hijo;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 24, child: Text(marcador, style: _estiloCuerpo(context))),
      Expanded(child: hijo),
    ],
  );
}

class _Lista extends StatelessWidget {
  const _Lista({required this.lista});

  final ListaGuia lista;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 6,
    children: [
      for (final (indice, item) in lista.items.indexed)
        _FilaConMarcador(
          marcador: lista.numerada ? '${indice + 1}.' : '•',
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              _TextoConEtiqueta(texto: item.texto, etiqueta: item.etiqueta),
              for (final subitem in item.subitems)
                _FilaConMarcador(
                  marcador: '–',
                  hijo: _TextoConEtiqueta(texto: subitem),
                ),
            ],
          ),
        ),
    ],
  );
}

/// Cada fila de la tabla se lee como un renglón con título y datos rotulados,
/// así entra en 360 px sin scroll horizontal.
class _Tabla extends StatelessWidget {
  const _Tabla({required this.tabla, required this.viewModel});

  final TablaGuia tabla;
  final GuiaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final semanaActual = viewModel.semanaActual;
    final semanaResaltada = viewModel.semanaResaltada;
    final resalta =
        tabla.filasPorSemana && semanaActual != null && semanaResaltada != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resalta)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              semanaActual == semanaResaltada
                  ? 'Estás en la semana $semanaActual.'
                  : 'Vas por la semana $semanaActual, que repite la $semanaResaltada del plan.',
              style: _estiloCuerpo(context)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        for (final (indice, fila) in tabla.filas.indexed)
          _FilaTabla(
            encabezados: tabla.encabezados,
            fila: fila,
            resaltada: resalta && indice + 1 == semanaResaltada,
          ),
      ],
    );
  }
}

class _FilaTabla extends StatelessWidget {
  const _FilaTabla({
    required this.encabezados,
    required this.fila,
    required this.resaltada,
  });

  final List<String> encabezados;
  final List<String> fila;
  final bool resaltada;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final colorTexto = resaltada
        ? esquema.onPrimaryContainer
        : esquema.onSurface;
    final colorRotulo = resaltada
        ? esquema.onPrimaryContainer
        : esquema.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: resaltada ? esquema.primaryContainer : null,
        border: Border(bottom: BorderSide(color: esquema.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fila.first,
                  style: tema.textTheme.titleSmall?.copyWith(color: colorTexto),
                ),
              ),
              if (resaltada)
                Text(
                  'Estás acá',
                  style: tema.textTheme.labelLarge?.copyWith(
                    color: colorTexto,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          for (var columna = 1; columna < fila.length; columna++)
            if (fila[columna].isNotEmpty)
              Text.rich(
                TextSpan(
                  style: _estiloCuerpo(context)?.copyWith(color: colorTexto),
                  children: [
                    TextSpan(
                      text: '${encabezados[columna]}: ',
                      style: TextStyle(color: colorRotulo),
                    ),
                    TextSpan(text: fila[columna]),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
