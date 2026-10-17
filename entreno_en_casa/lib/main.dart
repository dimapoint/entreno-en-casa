import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repositories/repositorio_entrenamiento.dart';
import 'data/services/servicio_almacenamiento.dart';
import 'data/services/servicio_api.dart';
import 'ui/core/pantalla_principal.dart';
import 'ui/core/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final almacenamiento = await ServicioAlmacenamiento.crear();
  runApp(AplicacionEntreno(almacenamiento: almacenamiento));
}

class AplicacionEntreno extends StatelessWidget {
  const AplicacionEntreno({super.key, required this.almacenamiento, this.api});

  final ServicioAlmacenamiento almacenamiento;
  final ServicioApi? api;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) {
          final repositorio = RepositorioEntrenamiento(
            almacenamiento: almacenamiento,
            api: api ?? ServicioApi(),
          );
          unawaited(repositorio.iniciar());
          return repositorio;
        },
        child: MaterialApp(
          title: 'Entreno en casa',
          debugShowCheckedModeBanner: false,
          theme: Tema.claro(),
          darkTheme: Tema.oscuro(),
          locale: const Locale('es', 'AR'),
          supportedLocales: const [Locale('es', 'AR'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const PantallaPrincipal(),
        ),
      );
}
