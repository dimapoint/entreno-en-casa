import 'package:flutter/material.dart';

import '../features/ajustes/views/pantalla_ajustes.dart';
import '../features/guia/views/pantalla_guia.dart';
import '../features/hoy/views/pantalla_hoy.dart';
import '../features/progreso/views/pantalla_progreso.dart';

class _Destino {
  const _Destino(this.etiqueta, this.icono, this.iconoActivo);

  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
}

const _destinos = [
  _Destino('Hoy', Icons.today_outlined, Icons.today),
  _Destino('Progreso', Icons.show_chart, Icons.show_chart),
  _Destino('Guía', Icons.menu_book_outlined, Icons.menu_book),
  _Destino('Ajustes', Icons.settings_outlined, Icons.settings),
];

const _indiceProgreso = 1;
const _anchoMinimoParaRiel = 900.0;
const _anchoMaximoDelContenido = 720.0;

/// Barra inferior en el celular y riel lateral en pantallas anchas.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _EstadoPantallaPrincipal();
}

class _EstadoPantallaPrincipal extends State<PantallaPrincipal> {
  int _indice = 0;

  void _seleccionar(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    final conRiel = MediaQuery.sizeOf(context).width >= _anchoMinimoParaRiel;
    return Scaffold(
      body: Row(
        children: [
          if (conRiel) ...[
            NavigationRail(
              selectedIndex: _indice,
              onDestinationSelected: _seleccionar,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destino in _destinos)
                  NavigationRailDestination(
                    icon: Icon(destino.icono),
                    selectedIcon: Icon(destino.iconoActivo),
                    label: Text(destino.etiqueta),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
          ],
          // La clave conserva el estado de las pestañas si la ventana cruza el ancho del riel.
          Expanded(
            key: const ValueKey('contenido'),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _anchoMaximoDelContenido),
                child: IndexedStack(
                  index: _indice,
                  children: [
                    PantallaHoy(irAProgreso: () => _seleccionar(_indiceProgreso)),
                    const PantallaProgreso(),
                    const PantallaGuia(),
                    const PantallaAjustes(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: conRiel
          ? null
          : NavigationBar(
              selectedIndex: _indice,
              onDestinationSelected: _seleccionar,
              destinations: [
                for (final destino in _destinos)
                  NavigationDestination(
                    icon: Icon(destino.icono),
                    selectedIcon: Icon(destino.iconoActivo),
                    label: destino.etiqueta,
                  ),
              ],
            ),
    );
  }
}
