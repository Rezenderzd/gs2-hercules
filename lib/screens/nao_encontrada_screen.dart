import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../rotas.dart';
import '../widgets/base.dart';
import '../widgets/estados.dart';

class NaoEncontradaScreen extends StatelessWidget {
  const NaoEncontradaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraTopo(),
      body: Centralizado(
        child: EstadoTela.vazio(
          icone: Icons.explore_off,
          titulo: 'Página não encontrada',
          rotuloAcao: 'Ir para o Início',
          acao: () => context.goNamed(Rotas.inicio),
        ),
      ),
    );
  }
}
