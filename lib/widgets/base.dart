import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/indice_atencao.dart';
import '../models/alerta.dart';
import '../state/escopos.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';

class Cartao extends StatelessWidget {
  const Cartao({super.key, required this.child, this.aoTocar, this.leitura, this.preenchimento});

  final Widget child;
  final VoidCallback? aoTocar;

  final String? leitura;
  final EdgeInsetsGeometry? preenchimento;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final conteudo = Padding(padding: preenchimento ?? const EdgeInsets.all(Espacos.margem), child: child);
    return Semantics(
      container: true,
      button: aoTocar != null,
      label: leitura,
      excludeSemantics: leitura != null,
      child: Material(
        color: cores.cartao,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Espacos.raio),
          side: BorderSide(color: cores.linha),
        ),
        clipBehavior: Clip.antiAlias,
        child: aoTocar == null ? conteudo : InkWell(onTap: aoTocar, child: conteudo),
      ),
    );
  }
}

class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.acao, this.aoTocarAcao});

  final String texto;
  final String? acao;
  final VoidCallback? aoTocarAcao;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Padding(
      padding: const EdgeInsets.only(top: Espacos.enorme, bottom: Espacos.pequeno),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(texto, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cores.suave)),
            ),
          ),
          if (acao != null) TextButton(onPressed: aoTocarAcao, child: Text(acao!)),
        ],
      ),
    );
  }
}

class Marcador extends StatelessWidget {
  const Marcador(this.cor, {super.key, this.tamanho = 10});

  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      ),
    );
  }
}

Color corDoNivel(Cores cores, NivelAtencao nivel) {
  return switch (nivel) {
    NivelAtencao.tranquilo => cores.ok,
    NivelAtencao.atencao => cores.atencao,
    NivelAtencao.alto => cores.critico,
  };
}

Color corDaGravidade(Cores cores, Gravidade gravidade) {
  return gravidade == Gravidade.critico ? cores.critico : cores.atencao;
}

class Pagina extends StatelessWidget {
  const Pagina({super.key, required this.children, this.aoAtualizar, this.formulario = false});

  final List<Widget> children;
  final Future<void> Function()? aoAtualizar;

  final bool formulario;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final lateral = math.max(Espacos.margem, (largura - Espacos.larguraMaxima) / 2);
    final margens = EdgeInsets.fromLTRB(lateral, Espacos.pequeno, lateral, Espacos.enorme * 2);
    final Widget lista = formulario
        ? SingleChildScrollView(
            padding: margens,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          )
        : ListView(padding: margens, children: children);
    final atualizar = aoAtualizar;
    return atualizar == null ? lista : RefreshIndicator(onRefresh: atualizar, child: lista);
  }
}

class AvisoFaixa extends StatelessWidget {
  const AvisoFaixa(this.texto, {super.key, this.icone = Icons.info_outline});

  final String texto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Espacos.medio),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icone, size: 20, color: cores.atencao)),
            const SizedBox(width: Espacos.pequeno),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cores.atencao),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotaDecisaoHumana extends StatelessWidget {
  const NotaDecisaoHumana({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacos.medio),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(Icons.person_outline, size: 20, color: cores.destaque)),
            const SizedBox(width: Espacos.pequeno),
            Expanded(
              child: Text(
                'Os alertas apoiam, mas não substituem, a decisão humana. '
                'O app nunca age sozinho.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cores.suave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BotaoModo extends StatelessWidget {
  const BotaoModo({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencias = PreferenciasEscopo.de(context);
    final escuro = preferencias.modoEscuro;
    final acao = escuro ? 'Ativar modo claro' : 'Ativar modo escuro';
    return IconButton(
      tooltip: acao,
      onPressed: () => preferencias.definirModoEscuro(!escuro),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (filho, animacao) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(animacao),
          child: FadeTransition(opacity: animacao, child: filho),
        ),
        child: Icon(
          escuro ? Icons.light_mode : Icons.dark_mode_outlined,
          key: ValueKey(escuro),
          semanticLabel: acao,
        ),
      ),
    );
  }
}

class BarraTopo extends StatelessWidget implements PreferredSizeWidget {
  const BarraTopo({super.key, this.title, this.actions = const []});

  final Widget? title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: [...actions, const BotaoModo(), const SizedBox(width: Espacos.minimo)],
    );
  }
}
