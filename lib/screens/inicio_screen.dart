import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/territorio.dart';
import '../logic/indice_atencao.dart';
import '../models/decisao.dart';
import '../models/indicador.dart';
import '../models/origem.dart';
import '../rotas.dart';
import '../state/escopos.dart';
import '../state/status_carga.dart';
import '../state/territorio_store.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../widgets/base.dart';
import '../widgets/estados.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final territorio = TerritorioEscopo.de(context);

    return Scaffold(
      appBar: BarraTopo(
        title: const Text('São Paulo Atento'),
        actions: [
          IconButton(
            tooltip: 'Como funcionam os números',
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.pushNamed(Rotas.sobre),
          ),
        ],
      ),
      body: !territorio.temDados
          ? Centralizado(
              child: territorio.status == StatusCarga.erro
                  ? EstadoTela.erro(texto: territorio.erro ?? '', aoTentar: territorio.carregar)
                  : const EstadoTela.carregando(titulo: 'Buscando os dados do Centro...'),
            )
          : Pagina(aoAtualizar: territorio.carregar, children: _conteudo(context, territorio)),
    );
  }

  List<Widget> _conteudo(BuildContext context, TerritorioStore territorio) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    final indice = territorio.indiceGeral;
    final nivel = NivelAtencao.de(indice);
    final hoje = DateTime.now();
    final pendentes = territorio.alertas
        .where((a) => territorio.decisaoDe(a.id) == Decisao.aguardando)
        .toList();
    final impacto = territorio.impacto(relatos: RelatosEscopo.de(context).relatos.length);

    return [
      if (territorio.carregando) const LinearProgressIndicator(minHeight: 2),
      if (territorio.avisoAtualizacao != null) AvisoFaixa(territorio.avisoAtualizacao!),
      if (territorio.aviso != null) AvisoFaixa(territorio.aviso!, icone: Icons.cloud_off_outlined),
      Text(
        '${Territorio.nome} · ${Formato.diaSemana(hoje)}, ${Formato.dia(hoje)}',
        style: estilos.bodyMedium?.copyWith(color: cores.suave),
      ),
      const SizedBox(height: Espacos.grande),
      Semantics(
        label: 'Índice de atenção: ${indice.round()} de 100, ${nivel.rotulo}. ${_frase(nivel)}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Índice de atenção', style: estilos.bodyMedium?.copyWith(color: cores.suave)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${indice.round()}',
                  style: estilos.displayLarge?.copyWith(fontWeight: FontWeight.w300),
                ),
                const SizedBox(width: Espacos.medio),
                Marcador(corDoNivel(cores, nivel), tamanho: 12),
                const SizedBox(width: Espacos.pequeno),
                Flexible(child: Text(nivel.rotulo, style: estilos.titleLarge)),
              ],
            ),
            Text(_frase(nivel), style: estilos.bodyLarge?.copyWith(color: cores.suave)),
          ],
        ),
      ),
      const TituloSecao('Temas'),
      Cartao(
        preenchimento: EdgeInsets.zero,
        child: Column(
          children: [
            for (final tema in Tema.values) ...[
              _LinhaTema(tema: tema, indice: territorio.indiceDo(tema)),
              if (tema != Tema.values.last) const Divider(indent: Espacos.margem),
            ],
          ],
        ),
      ),
      const TituloSecao('Para decidir'),
      if (pendentes.isEmpty)
        Text('Nenhum alerta aguardando decisão.', style: estilos.bodyLarge?.copyWith(color: cores.suave))
      else
        Cartao(
          aoTocar: () => context.goNamed(Rotas.alertas),
          leitura: '${pendentes.length} alerta(s) aguardando decisão. O primeiro: '
              '${pendentes.first.titulo}. Toque para ver.',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pendentes.length == 1 ? '1 alerta aguardando' : '${pendentes.length} alertas aguardando',
                      style: estilos.titleMedium,
                    ),
                    const SizedBox(height: Espacos.minimo),
                    Text(pendentes.first.titulo, style: estilos.bodyMedium?.copyWith(color: cores.suave)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cores.suave),
            ],
          ),
        ),
      const TituloSecao('Impacto'),
      Text(
        '≈ ${(impacto.moradores / 1000).round()} mil moradores acompanhados'
        '${impacto.antecedenciaMedia == null ? '' : ' · ${Formato.numero(impacto.antecedenciaMedia!)} dias de antecedência média'}'
        ' · ${impacto.relatos} relato(s) de cidadãos.',
        style: estilos.bodyLarge,
      ),
      const SizedBox(height: Espacos.enorme),
      Text(
        _origem(territorio),
        style: estilos.bodySmall?.copyWith(color: cores.suave),
      ),
    ];
  }

  static String _frase(NivelAtencao nivel) {
    return switch (nivel) {
      NivelAtencao.tranquilo => 'Tudo dentro do esperado.',
      NivelAtencao.atencao => 'Alguns pontos merecem acompanhamento.',
      NivelAtencao.alto => 'Há indicadores pedindo avaliação.',
    };
  }

  static String _origem(TerritorioStore territorio) {
    final quando = territorio.climaAtualizadoEm;
    final clima = switch (territorio.origemClima) {
      Origem.aoVivo => 'Clima ao vivo (Open-Meteo)${quando == null ? '' : ', ${Formato.dataHora(quando)}'}.',
      Origem.cache => 'Sem internet: clima do último cache${quando == null ? '' : ', ${Formato.dataHora(quando)}'}.',
      Origem.simulado => 'Sem internet e sem cache: clima simulado.',
    };
    return '$clima Mobilidade e limpeza usam dados simulados.';
  }
}

class _LinhaTema extends StatelessWidget {
  const _LinhaTema({required this.tema, required this.indice});

  final Tema tema;
  final double indice;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final nivel = NivelAtencao.de(indice);
    return Semantics(
      button: true,
      label: '${tema.titulo}: ${nivel.rotulo}, índice ${indice.round()}. Abrir painel.',
      excludeSemantics: true,
      child: ListTile(
        minVerticalPadding: Espacos.medio,
        contentPadding: const EdgeInsets.symmetric(horizontal: Espacos.margem),
        leading: Icon(tema.icone, color: cores.texto),
        title: Text(tema.titulo),
        subtitle: Row(
          children: [
            Marcador(corDoNivel(cores, nivel), tamanho: 8),
            const SizedBox(width: Espacos.pequeno),
            Text(nivel.rotulo),
          ],
        ),
        trailing: Text('${indice.round()}', style: Theme.of(context).textTheme.titleLarge),
        onTap: () => context.pushNamed(Rotas.painelDe(tema)),
      ),
    );
  }
}
