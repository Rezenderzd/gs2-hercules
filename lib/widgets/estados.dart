import 'package:flutter/material.dart';

import '../theme/cores.dart';
import '../theme/espacos.dart';

/// Estados de tela: carregando, erro e vazio. Sem ilustrações pesadas —
/// um ícone, uma frase e, quando faz sentido, uma ação.
class EstadoTela extends StatelessWidget {
  const EstadoTela._({
    required this.icone,
    required this.titulo,
    this.texto,
    this.acao,
    this.rotuloAcao,
    this.carregando = false,
  });

  const EstadoTela.carregando({String titulo = 'Carregando...'})
      : this._(icone: null, titulo: titulo, carregando: true);

  const EstadoTela.erro({required String texto, VoidCallback? aoTentar})
      : this._(
          icone: Icons.cloud_off_outlined,
          titulo: 'Não foi possível carregar',
          texto: texto,
          acao: aoTentar,
          rotuloAcao: 'Tentar de novo',
        );

  const EstadoTela.vazio({
    required IconData icone,
    required String titulo,
    String? texto,
    VoidCallback? acao,
    String? rotuloAcao,
  }) : this._(icone: icone, titulo: titulo, texto: texto, acao: acao, rotuloAcao: rotuloAcao);

  final IconData? icone;
  final String titulo;
  final String? texto;
  final VoidCallback? acao;
  final String? rotuloAcao;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: carregando || acao != null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacos.enorme, horizontal: Espacos.medio),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (carregando)
              const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3))
            else
              Icon(icone, size: 32, color: cores.suave),
            const SizedBox(height: Espacos.medio),
            Text(titulo, textAlign: TextAlign.center, style: estilos.titleMedium),
            if (texto != null) ...[
              const SizedBox(height: Espacos.pequeno),
              Text(texto!, textAlign: TextAlign.center, style: estilos.bodyMedium?.copyWith(color: cores.suave)),
            ],
            if (acao != null && rotuloAcao != null) ...[
              const SizedBox(height: Espacos.medio),
              OutlinedButton(
                onPressed: acao,
                style: OutlinedButton.styleFrom(minimumSize: const Size(Espacos.toque, Espacos.toque)),
                child: Text(rotuloAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centraliza um [EstadoTela] quando ele ocupa a tela inteira.
class Centralizado extends StatelessWidget {
  const Centralizado({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
      ),
    );
  }
}
