import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../logic/estatistica.dart';
import '../../logic/indice_atencao.dart';
import '../../logic/motor_alertas.dart';
import '../../models/indicador.dart';
import '../../models/serie.dart';
import '../../rotas.dart';
import '../../state/escopos.dart';
import '../../state/status_carga.dart';
import '../../state/territorio_store.dart';
import '../../theme/cores.dart';
import '../../theme/espacos.dart';
import '../../util/formato.dart';
import '../../widgets/base.dart';
import '../../widgets/estados.dart';
import '../../widgets/graficos.dart';

const _motor = MotorAlertas();

typedef ConstrutorDestaque = List<Widget> Function(BuildContext context, List<Serie> series);

class PainelTema extends StatefulWidget {
  const PainelTema({super.key, required this.tema, required this.tituloDestaque, required this.destaque});

  final Tema tema;
  final String tituloDestaque;
  final ConstrutorDestaque destaque;

  @override
  State<PainelTema> createState() => _PainelTemaState();
}

class _PainelTemaState extends State<PainelTema> {
  String? _indicadorGrafico;
  int _dias = 14;

  @override
  Widget build(BuildContext context) {
    final territorio = TerritorioEscopo.de(context);
    return Scaffold(
      appBar: BarraTopo(title: Text(widget.tema.titulo)),
      body: !territorio.temDados
          ? Centralizado(
              child: territorio.status == StatusCarga.erro
                  ? EstadoTela.erro(texto: territorio.erro ?? '', aoTentar: territorio.carregar)
                  : const EstadoTela.carregando(),
            )
          : Pagina(aoAtualizar: territorio.carregar, children: _conteudo(context, territorio)),
    );
  }

  List<Widget> _conteudo(BuildContext context, TerritorioStore territorio) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    final tema = widget.tema;
    final limites = PreferenciasEscopo.de(context).limites;
    final series = territorio.seriesDo(tema);
    final alertas = territorio.alertasDo(tema);
    final indice = territorio.indiceDo(tema);
    final nivel = NivelAtencao.de(indice);
    final escolhida = series.where((s) => s.indicador.id == _indicadorGrafico).firstOrNull ??
        series.firstOrNull;
    final referencia = escolhida == null ? null : _motor.referencia(escolhida, limites);
    final destaque = widget.destaque(context, series);

    return [
      if (territorio.avisoAtualizacao != null) AvisoFaixa(territorio.avisoAtualizacao!),
      Text(tema.descricao, style: estilos.bodyLarge?.copyWith(color: cores.suave)),
      const SizedBox(height: Espacos.grande),
      Semantics(
        label: 'Índice do tema: ${indice.round()} de 100, ${nivel.rotulo}',
        excludeSemantics: true,
        child: Row(
          children: [
            Text('${indice.round()}', style: estilos.displayMedium?.copyWith(fontWeight: FontWeight.w300)),
            const SizedBox(width: Espacos.medio),
            Marcador(corDoNivel(cores, nivel)),
            const SizedBox(width: Espacos.pequeno),
            Text(nivel.rotulo, style: estilos.titleMedium),
          ],
        ),
      ),
      const TituloSecao('Indicadores'),
      for (final serie in series)
        Padding(
          padding: const EdgeInsets.only(bottom: Espacos.entre),
          child: CartaoIndicador(serie: serie),
        ),
      if (escolhida != null) ...[
        const TituloSecao('Histórico'),
        Wrap(
          spacing: Espacos.pequeno,
          runSpacing: Espacos.pequeno,
          children: [
            for (final s in series)
              ChoiceChip(
                label: Text(s.indicador.nome),
                selected: s == escolhida,
                onSelected: (_) => setState(() => _indicadorGrafico = s.indicador.id),
              ),
          ],
        ),
        const SizedBox(height: Espacos.medio),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 dias')),
            ButtonSegment(value: 14, label: Text('14 dias')),
            ButtonSegment(value: 30, label: Text('30 dias')),
          ],
          selected: {_dias},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _dias = s.first),
        ),
        const SizedBox(height: Espacos.medio),
        Cartao(
          child: GraficoLinha(
            pontos: escolhida.recorte(_dias),
            descricao: escolhida.indicador.nome,
            unidade: escolhida.indicador.unidade,
            casas: escolhida.indicador.casas,
            referencias: referencia?.valores ?? const [],
            rotuloReferencia: referencia?.rotulo ?? 'limite',
          ),
        ),
      ],
      if (destaque.isNotEmpty) ...[
        TituloSecao(widget.tituloDestaque),
        ...destaque,
      ],
      const TituloSecao('Alertas deste tema'),
      if (alertas.isEmpty)
        Text('Nenhum alerta. Os indicadores estão dentro do esperado.',
            style: estilos.bodyLarge?.copyWith(color: cores.suave))
      else
        for (final alerta in alertas)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Marcador(corDaGravidade(cores, alerta.gravidade)),
            title: Text(alerta.titulo),
            subtitle: Text('${alerta.gravidade.rotulo} · evidência ${alerta.nivelQualidade.rotulo}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(Rotas.alerta, pathParameters: {'id': alerta.id}),
          ),
      const NotaDecisaoHumana(),
    ];
  }
}

class CartaoIndicador extends StatelessWidget {
  const CartaoIndicador({super.key, required this.serie});

  final Serie serie;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    final indicador = serie.indicador;
    final ultimo = serie.ultimo;
    final valor = ultimo == null ? '—' : Formato.numero(ultimo.valor, casas: indicador.casas);
    final valores = serie.valoresObservados;
    final tendencia = Tendencia.de(valores);
    final recentes = valores.length > 14 ? valores.sublist(valores.length - 14) : valores;
    final textoTendencia = tendencia == null
        ? null
        : '${Formato.variacao(tendencia.variacao)} nos últimos 7 dias';
    final leituraTendencia = switch (tendencia?.direcao) {
      null => '',
      Direcao.subindo => ', subindo: $textoTendencia',
      Direcao.caindo => ', caindo: $textoTendencia',
      Direcao.estavel => ', estável: $textoTendencia',
    };

    return Cartao(
      aoTocar: () => context.pushNamed(Rotas.indicador, pathParameters: {'id': indicador.id}),
      leitura: '${indicador.nome}: $valor ${indicador.unidade}$leituraTendencia. Toque para detalhes.',
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(indicador.nome, style: estilos.bodyMedium?.copyWith(color: cores.suave)),
                const SizedBox(height: Espacos.minimo),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: valor, style: estilos.headlineSmall),
                      TextSpan(text: ' ${indicador.unidade}', style: estilos.bodyMedium?.copyWith(color: cores.suave)),
                    ],
                  ),
                ),
                if (tendencia != null)
                  Row(
                    children: [
                      Icon(_iconeDe(tendencia.direcao), size: 16, color: cores.suave),
                      const SizedBox(width: Espacos.minimo),
                      Flexible(
                        child: Text(textoTendencia!, style: estilos.bodySmall?.copyWith(color: cores.suave)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: Espacos.medio),
          Expanded(flex: 2, child: MiniLinha(valores: recentes)),
        ],
      ),
    );
  }

  static IconData _iconeDe(Direcao direcao) => switch (direcao) {
        Direcao.subindo => Icons.trending_up,
        Direcao.caindo => Icons.trending_down,
        Direcao.estavel => Icons.trending_flat,
      };
}

class BarraSimples extends StatelessWidget {
  const BarraSimples({super.key, required this.rotulo, required this.valor, required this.maximo, this.sufixo = ''});

  final String rotulo;
  final double valor;
  final double maximo;
  final String sufixo;

  static const double _larguraRotulo = 120;
  static const double _larguraValor = 48;
  static const double _espessura = 6;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final texto = '${valor.round()}$sufixo';
    return Semantics(
      label: '$rotulo: $texto',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacos.minimo + 2),
        child: Row(
          children: [
            SizedBox(width: _larguraRotulo, child: Text(rotulo, overflow: TextOverflow.ellipsis)),
            Expanded(
              child: LinearProgressIndicator(
                value: maximo <= 0 ? 0 : (valor / maximo).clamp(0.0, 1.0).toDouble(),
                minHeight: _espessura,
                borderRadius: BorderRadius.circular(_espessura / 2),
                color: cores.destaque,
                backgroundColor: cores.linha,
              ),
            ),
            const SizedBox(width: Espacos.medio),
            SizedBox(width: _larguraValor, child: Text(texto, textAlign: TextAlign.end)),
          ],
        ),
      ),
    );
  }
}
