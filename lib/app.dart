import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/cores.dart';
import 'theme/tema_visual.dart';
import 'widgets/estados.dart';

class SaoPauloAtentoApp extends StatefulWidget {
  const SaoPauloAtentoApp({super.key});

  @override
  State<SaoPauloAtentoApp> createState() => _SaoPauloAtentoAppState();
}

class _SaoPauloAtentoAppState extends State<SaoPauloAtentoApp> {
  bool _escuro = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'São Paulo Atento',
      debugShowCheckedModeBanner: false,
      theme: TemaVisual.criar(Cores.para(escuro: _escuro, altoContraste: false)),
      themeAnimationDuration: const Duration(milliseconds: 250),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('São Paulo Atento'),
          actions: [
            IconButton(
              tooltip: _escuro ? 'Usar modo claro' : 'Usar modo escuro',
              icon: Icon(_escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: () => setState(() => _escuro = !_escuro),
            ),
          ],
        ),
        body: const Centralizado(
          child: EstadoTela.vazio(
            icone: Icons.location_city,
            titulo: 'Centro de São Paulo',
            texto: 'Calor, mobilidade e limpeza urbana em um só lugar. Em construção.',
          ),
        ),
      ),
    );
  }
}
