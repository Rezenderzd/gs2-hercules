import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/indicador.dart';
import 'screens/moldura_screen.dart';
import 'screens/nao_encontrada_screen.dart';
import 'state/preferencias_store.dart';

abstract final class Rotas {
  static const boasVindas = 'boasVindas';
  static const entrar = 'entrar';
  static const inicio = 'inicio';
  static const alertas = 'alertas';
  static const relatos = 'relatos';
  static const ajustes = 'ajustes';
  static const painelCalor = 'painelCalor';
  static const painelMobilidade = 'painelMobilidade';
  static const painelLimpeza = 'painelLimpeza';
  static const indicador = 'indicador';
  static const alerta = 'alerta';
  static const novoRelato = 'novoRelato';
  static const limites = 'limites';
  static const sobre = 'sobre';

  static String painelDe(Tema tema) => switch (tema) {
        Tema.calor => painelCalor,
        Tema.mobilidade => painelMobilidade,
        Tema.limpeza => painelLimpeza,
      };
}

GoRouter criarRotas(PreferenciasStore preferencias) {
  GoRoute aba(String caminho, String nome, GoRouterWidgetBuilder tela) {
    return GoRoute(path: caminho, name: nome, builder: tela);
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: preferencias,
    errorBuilder: (context, state) => const NaoEncontradaScreen(),
    routes: [
      GoRoute(
        path: '/boas-vindas',
        name: Rotas.boasVindas,
        builder: (context, state) => const _EmConstrucao('Boas-vindas'),
      ),
      GoRoute(
        path: '/entrar',
        name: Rotas.entrar,
        builder: (context, state) => const _EmConstrucao('Entrar'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navegacao) => MolduraScreen(navegacao: navegacao),
        branches: [
          StatefulShellBranch(routes: [aba('/', Rotas.inicio, (c, s) => const _EmConstrucao('Início'))]),
          StatefulShellBranch(routes: [aba('/alertas', Rotas.alertas, (c, s) => const _EmConstrucao('Alertas'))]),
          StatefulShellBranch(routes: [aba('/relatos', Rotas.relatos, (c, s) => const _EmConstrucao('Relatos'))]),
          StatefulShellBranch(routes: [aba('/ajustes', Rotas.ajustes, (c, s) => const _EmConstrucao('Ajustes'))]),
        ],
      ),
      GoRoute(
        path: '/painel/calor',
        name: Rotas.painelCalor,
        builder: (context, state) => const _EmConstrucao('Calor e clima'),
      ),
      GoRoute(
        path: '/painel/mobilidade',
        name: Rotas.painelMobilidade,
        builder: (context, state) => const _EmConstrucao('Mobilidade'),
      ),
      GoRoute(
        path: '/painel/limpeza',
        name: Rotas.painelLimpeza,
        builder: (context, state) => const _EmConstrucao('Limpeza urbana'),
      ),
      GoRoute(
        path: '/indicador/:id',
        name: Rotas.indicador,
        builder: (context, state) => const _EmConstrucao('Indicador'),
      ),
      GoRoute(
        path: '/alerta/:id',
        name: Rotas.alerta,
        builder: (context, state) => const _EmConstrucao('Alerta'),
      ),
      GoRoute(
        path: '/novo-relato',
        name: Rotas.novoRelato,
        builder: (context, state) => const _EmConstrucao('Novo relato'),
      ),
      GoRoute(
        path: '/limites',
        name: Rotas.limites,
        builder: (context, state) => const _EmConstrucao('Limites dos alertas'),
      ),
      GoRoute(
        path: '/sobre',
        name: Rotas.sobre,
        builder: (context, state) => const _EmConstrucao('Como funcionam os números'),
      ),
    ],
  );
}

class _EmConstrucao extends StatelessWidget {
  const _EmConstrucao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: const Center(child: Text('Tela em construção')),
    );
  }
}
