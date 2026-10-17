import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/repositorio_entrenamiento.dart';
import '../view_models/progreso_view_model.dart';
import 'pestana_historial.dart';
import 'pestana_mediciones.dart';

class PantallaProgreso extends StatefulWidget {
  const PantallaProgreso({super.key});

  @override
  State<PantallaProgreso> createState() => _EstadoPantallaProgreso();
}

class _EstadoPantallaProgreso extends State<PantallaProgreso> {
  late final ProgresoViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProgresoViewModel(
      repositorio: context.read<RepositorioEntrenamiento>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Mediciones'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          PestanaMediciones(viewModel: _viewModel),
          PestanaHistorial(viewModel: _viewModel),
        ],
      ),
    ),
  );
}
