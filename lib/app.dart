import 'package:flutter/material.dart';

/// Ponto de partida do São Paulo Atento: por enquanto, só uma tela inicial.
class SaoPauloAtentoApp extends StatelessWidget {
  const SaoPauloAtentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'São Paulo Atento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const Scaffold(
        body: Center(
          child: Text('São Paulo Atento', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
