import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/estatistica.dart';
import '../logic/motor_alertas.dart';
import '../models/indicador.dart';
import '../models/origem.dart';
import '../models/serie.dart';
import '../rotas.dart';
import '../state/escopos.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../widgets/base.dart';
import '../widgets/estados.dart';
import '../widgets/graficos.dart';

class IndicadorScreen extends StatelessWidget {
  const IndicadorScreen({super.key, required this.indicadorId});

  final String indicadorId;

  @override
  Widget build(BuildContext context) {
    final territorio = TerritorioEscopo.de(context);
    final serie = territorio.serie(indicadorId);

    return Scaffold(
      appBar: BarraTopo(title: Text(serie?.indicador.nome ?? 'Indicador')),
      body: serie == null
          ? Centralizado(
              child: territorio.carregando
                  ? const EstadoTela.carregando()
                  : const EstadoTela.vazio(
                      icone: Icons.query_stats,
                      titulo: 'Sem dados deste indicador',
                      texto: 'Atualize o Início e tente de novo.',
                    ),
            )
          : Pagina(children: _conteudo(context, serie)),
    );
  }

  List<Widget> _conteudo(BuildContext context, Serie serie) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    final territorio = TerritorioEscopo.de(context);
    final limites = PreferenciasEscopo.de(context).limites;
    const motor = MotorAlertas();
    final indicador = serie.indicador;
    final valores = serie.valoresObservados;
    final ultimo = serie.ultimo;
    String fmt(double v) => Formato.numero(v, casas: indicador.casas);
    final amostra = Amostra(valores);
    final projecao = Projecao.de(valores);
    final erro = projecao.mape;
    final z = motor.escoreRecente(serie);
    final referencia = motor.referencia(serie, limites);
    final alertas = territorio.alertasDoIndicador(indicador.id);

    final avisos = [
      if (serie.origem == Origem.simulado) 'Os dados são simulados: mostram o método, não a realidade.',
      if (serie.origem == Origem.cache) 'Dados do cache de ${Formato.dataHora(serie.atualizadaEm)}.',
      if (valores.length < 21) 'Histórico curto: as estatísticas oscilam mais.',
      if (indicador.regra == RegraAlerta.anomalia)
        'A linha tracejada marca onde a média de 3 dias passa a ser considerada '
            '${indicador.sentido == SentidoAnomalia.ambos ? 'fora do padrão (para cima ou para baixo)' : 'fora do padrão'}.',
      if (erro != null && erro > 15) 'A projeção erra em média ${Formato.numero(erro)}%.',
      'Feriados, obras e temporais fora do padrão podem surpreender.',
    ];

    return [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: ultimo == null ? '—' : fmt(ultimo.valor),
              style: estilos.displayMedium?.copyWith(fontWeight: FontWeight.w300),
            ),
            TextSpan(text: ' ${indicador.unidade}', style: estilos.titleLarge?.copyWith(color: cores.suave)),
          ],
        ),
      ),
      Text(
        ultimo == null ? indicador.descricao : 'Em ${Formato.data(ultimo.dia)}. ${indicador.descricao}',
        style: estilos.bodyMedium?.copyWith(color: cores.suave),
      ),
      const TituloSecao('Últimos 30 dias'),
      Cartao(
        child: GraficoLinha(
          pontos: serie.pontos,
          descricao: indicador.nome,
          unidade: indicador.unidade,
          casas: indicador.casas,
          altura: 200,
          referencias: referencia?.valores ?? const [],
          rotuloReferencia: referencia?.rotulo ?? 'limite',
        ),
      ),
      const TituloSecao('Números-chave'),
      Cartao(
        child: Wrap(
          spacing: Espacos.grande,
          runSpacing: Espacos.medio,
          children: [
            _Numero('Média', fmt(amostra.media)),
            _Numero('Desvio padrão', fmt(amostra.desvio)),
            if (indicador.regra == RegraAlerta.anomalia)
              _Numero('Escore z da média de 3 dias', z == null ? '—' : Formato.numero(z))
            else
              _Numero(
                'Pico previsto',
                serie.previstos.isEmpty
                    ? '—'
                    : fmt(serie.previstos.map((p) => p.valor).reduce((a, b) => a > b ? a : b)),
              ),
            _Numero('Projeção de amanhã', fmt(projecao.proximoDia)),
            _Numero('Erro da projeção', erro == null ? '—' : '${Formato.numero(erro)}%'),
          ],
        ),
      ),
      const SizedBox(height: Espacos.medio),
      Text(
        'Fonte: ${indicador.fonte}.',
        style: estilos.bodySmall?.copyWith(color: cores.suave),
      ),
      const SizedBox(height: Espacos.pequeno),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Quando desconfiar deste número'),
        shape: const Border(),
        collapsedShape: const Border(),
        expandedAlignment: Alignment.centerLeft,
        children: [
          for (final aviso in avisos)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.pequeno),
              child: Text('• $aviso', style: estilos.bodyMedium),
            ),
        ],
      ),
      if (alertas.isNotEmpty) ...[
        const TituloSecao('Alertas'),
        for (final alerta in alertas)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Marcador(corDaGravidade(cores, alerta.gravidade)),
            title: Text(alerta.titulo),
            subtitle: Text('${alerta.gravidade.rotulo} · evidência ${alerta.nivelQualidade.rotulo}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(Rotas.alerta, pathParameters: {'id': alerta.id}),
          ),
      ],
    ];
  }
}

class _Numero extends StatelessWidget {
  const _Numero(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Semantics(
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rotulo, style: estilos.bodySmall?.copyWith(color: Cores.de(context).suave)),
            Text(valor, style: estilos.titleLarge),
          ],
        ),
      ),
    );
  }
}
