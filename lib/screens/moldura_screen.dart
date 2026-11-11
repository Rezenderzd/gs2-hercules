import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/escopos.dart';

class MolduraScreen extends StatelessWidget {
  const MolduraScreen({super.key, required this.navegacao});

  final StatefulNavigationShell navegacao;

  @override
  Widget build(BuildContext context) {
    final pendentes = TerritorioEscopo.de(context).pendentes;

    return Scaffold(
      body: navegacao,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navegacao.currentIndex,
        onDestinationSelected: (i) => navegacao.goBranch(i, initialLocation: i == navegacao.currentIndex),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendentes > 0,
              label: Text('$pendentes'),
              child: const Icon(Icons.notifications_none),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alertas',
            tooltip: pendentes > 0 ? 'Alertas, $pendentes aguardando decisão' : 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Relatos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
