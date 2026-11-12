import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/relato.dart';
import '../rotas.dart';
import '../state/escopos.dart';
import '../state/status_carga.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../widgets/base.dart';
import '../widgets/estados.dart';

class RelatosScreen extends StatelessWidget {
  const RelatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final relatos = RelatosEscopo.de(context);
    final cores = Cores.de(context);
    void novo() => context.pushNamed(Rotas.novoRelato);

    final Widget corpo;
    if (relatos.relatos.isEmpty &&
        (relatos.status == StatusCarga.carregando || relatos.status == StatusCarga.inicial)) {
      corpo = const Centralizado(child: EstadoTela.carregando());
    } else if (relatos.relatos.isEmpty) {
      corpo = Centralizado(
        child: EstadoTela.vazio(
          icone: Icons.chat_bubble_outline,
          titulo: 'Nenhum relato ainda',
          texto: relatos.aviso ??
              'Viu lixo acumulado, ônibus lotado ou alagamento? Conte aqui. '
                  'O relato é público, sem o seu e-mail.',
          rotuloAcao: 'Fazer um relato',
          acao: novo,
        ),
      );
    } else {
      corpo = Pagina(
        aoAtualizar: relatos.carregar,
        children: [
          if (relatos.aviso != null)
            AvisoFaixa(relatos.aviso!, icone: Icons.cloud_off_outlined)
          else
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.medio),
              child: Text(
                relatos.usaNuvem
                    ? 'Relatos de todos os usuários, sem identificação de quem escreveu.'
                    : 'Relatos salvos neste aparelho.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cores.suave),
              ),
            ),
          for (final relato in relatos.relatos)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.entre),
              child: _CartaoRelato(relato: relato),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: BarraTopo(
        title: const Text('Relatos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: relatos.status == StatusCarga.carregando ? null : relatos.carregar,
          ),
          IconButton(tooltip: 'Novo relato', icon: const Icon(Icons.add), onPressed: novo),
        ],
      ),
      body: corpo,
    );
  }
}

class _CartaoRelato extends StatelessWidget {
  const _CartaoRelato({required this.relato});

  final Relato relato;

  static const double _marcador = 8;
  static const double _icone = 16;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    final cor = switch (relato.urgencia) {
      Urgencia.alta => cores.critico,
      Urgencia.media => cores.atencao,
      Urgencia.baixa => cores.ok,
    };
    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(relato.categoria.rotulo, style: estilos.titleMedium),
          const SizedBox(height: Espacos.minimo),
          Text(
            '${relato.bairro} · ${Formato.data(relato.observadoEm)}${relato.meu ? ' · por você' : ''}',
            style: estilos.bodySmall?.copyWith(color: cores.suave),
          ),
          const SizedBox(height: Espacos.entre),
          Text(relato.descricao, style: estilos.bodyLarge),
          const SizedBox(height: Espacos.entre),
          Row(
            children: [
              Marcador(cor, tamanho: _marcador),
              const SizedBox(width: Espacos.pequeno),
              Text('Urgência ${relato.urgencia.rotulo.toLowerCase()}', style: estilos.bodySmall),
              if (relato.pendente) ...[
                const Spacer(),
                Icon(Icons.cloud_off_outlined, size: _icone, color: cores.atencao),
                const SizedBox(width: Espacos.minimo),
                Text('Aguardando envio', style: estilos.bodySmall?.copyWith(color: cores.atencao)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
