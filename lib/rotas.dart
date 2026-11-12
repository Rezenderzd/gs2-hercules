import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/indicador.dart';
import 'screens/novo_relato_screen.dart';
import 'screens/relatos_screen.dart';
import 'screens/alerta_screen.dart';
import 'screens/alertas_screen.dart';
import 'screens/indicador_screen.dart';
import 'screens/paineis/painel_limpeza_screen.dart';
import 'screens/paineis/painel_mobilidade_screen.dart';
import 'screens/paineis/painel_calor_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/entrar_screen.dart';
import 'screens/boas_vindas_screen.dart';
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
    redirect: (context, state) {
      final local = state.matchedLocation;
      if (!preferencias.aceitou) return local == '/boas-vindas' ? null : '/boas-vindas';
      if (local == '/boas-vindas') return '/';
      if (local == '/novo-relato' && !preferencias.entrou) {
        return '/entrar?de=${Rotas.novoRelato}';
      }
      return null;
    },
    errorBuilder: (context, state) => const NaoEncontradaScreen(),
    routes: [
      GoRoute(
        path: '/boas-vindas',
        name: Rotas.boasVindas,
        builder: (context, state) => const BoasVindasScreen(),
      ),
      GoRoute(
        path: '/entrar',
        name: Rotas.entrar,
        builder: (context, state) => EntrarScreen(destino: state.uri.queryParameters['de']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navegacao) => MolduraScreen(navegacao: navegacao),
        branches: [
          StatefulShellBranch(routes: [aba('/', Rotas.inicio, (c, s) => const InicioScreen())]),
          StatefulShellBranch(routes: [aba('/alertas', Rotas.alertas, (c, s) => const AlertasScreen())]),
          StatefulShellBranch(routes: [aba('/relatos', Rotas.relatos, (c, s) => const RelatosScreen())]),
          StatefulShellBranch(routes: [aba('/ajustes', Rotas.ajustes, (c, s) => const _EmConstrucao('Ajustes'))]),
        ],
      ),
      GoRoute(
        path: '/painel/calor',
        name: Rotas.painelCalor,
        builder: (context, state) => const PainelCalorScreen(),
      ),
      GoRoute(
        path: '/painel/mobilidade',
        name: Rotas.painelMobilidade,
        builder: (context, state) => const PainelMobilidadeScreen(),
      ),
      GoRoute(
        path: '/painel/limpeza',
        name: Rotas.painelLimpeza,
        builder: (context, state) => const PainelLimpezaScreen(),
      ),
      GoRoute(
        path: '/indicador/:id',
        name: Rotas.indicador,
        builder: (context, state) => IndicadorScreen(indicadorId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/alerta/:id',
        name: Rotas.alerta,
        builder: (context, state) => AlertaScreen(alertaId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/novo-relato',
        name: Rotas.novoRelato,
        builder: (context, state) => const NovoRelatoScreen(),
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
