import 'dart:math' as math;

import '../../models/alerta.dart';
import '../../models/indicador.dart';
import '../../models/limites.dart';
import '../../models/serie.dart';
import '../../util/datas.dart';
import '../../util/formato.dart';
import '../estatistica.dart';
import 'fundamentos.dart';

/// Recorte da série para a regra de anomalia: os dias recentes e a base
/// histórica imediatamente anterior a eles.
class Janela {
  Janela._(this.recentes, this.base);

  final Amostra recentes;
  final Amostra base;

  /// Escore z da média recente (veja `Amostra.escoreDaMedia`).
  late final double escore = base.escoreDaMedia(recentes);
}

/// Regra 2 — mobilidade e limpeza: a média dos últimos [diasRecentes] dias
/// foge do padrão dos [diasBase] dias anteriores, no sentido que importa
/// para o indicador (`SentidoAnomalia`).
class RegraAnomalia {
  const RegraAnomalia();

  static const int diasRecentes = 3;
  static const int diasBase = 21;

  /// Com menos dias de base, a regra não avalia.
  static const int baseMinima = 10;

  /// Janela cujos dias recentes terminam no índice [fim] de [valores].
  /// `null` se não houver base suficiente antes dela.
  static Janela? janela(List<double> valores, int fim) {
    final inicioRecentes = fim - diasRecentes + 1;
    if (fim >= valores.length || inicioRecentes - baseMinima < 0) return null;
    final inicioBase = math.max(0, inicioRecentes - diasBase);
    return Janela._(
      Amostra(valores.sublist(inicioRecentes, fim + 1)),
      Amostra(valores.sublist(inicioBase, inicioRecentes)),
    );
  }

  /// Janela mais recente da série, ou `null` com histórico curto.
  static Janela? atual(Serie serie) {
    final valores = serie.valoresObservados;
    return janela(valores, valores.length - 1);
  }

  /// O escore está fora do padrão no sentido do indicador?
  static bool foraDoPadrao(double escore, SentidoAnomalia sentido, double limite) {
    return switch (sentido) {
      SentidoAnomalia.alta => escore >= limite,
      SentidoAnomalia.baixa => escore <= -limite,
      SentidoAnomalia.ambos => escore.abs() >= limite,
    };
  }

  Alerta? avaliar(Serie serie, Limites limites, DateTime agora) {
    final indicador = serie.indicador;
    final observados = serie.observados;
    final valores = [for (final p in observados) p.valor];
    final ultima = janela(valores, valores.length - 1);
    if (ultima == null) return null;

    final escore = ultima.escore;
    if (!foraDoPadrao(escore, indicador.sentido, limites.escoreZ)) return null;
    final subiu = escore > 0;

    // Recua enquanto o desvio continua, no mesmo sentido: o id do alerta usa
    // o primeiro dia do episódio e não muda enquanto o problema durar.
    var inicio = valores.length - 1;
    while (true) {
      final anterior = janela(valores, inicio - 1);
      if (anterior == null) break;
      final mesmoSentido = (anterior.escore > 0) == subiu;
      if (!mesmoSentido || !foraDoPadrao(anterior.escore, indicador.sentido, limites.escoreZ)) break;
      inicio--;
    }
    final diaInicio = observados[inicio].dia;
    final diasNoEpisodio = valores.length - inicio;

    final projecao = Projecao.de(valores);
    final variacao = ultima.base.variacaoPercentualPara(ultima.recentes) ?? 0;
    final ruido = ultima.base.variacaoRelativa;
    final intensidade = escore.abs();
    final unidade = indicador.unidade;
    String valor(double v) => '${Formato.numero(v, casas: indicador.casas)} $unidade';
    final direcao = subiu ? 'acima' : 'abaixo';

    final fatores = {
      'Histórico disponível': (valores.length / 24).clamp(0.4, 1.0).toDouble(),
      'Estabilidade da base': (1 - ruido).clamp(0.3, 1.0).toDouble(),
      'Força do sinal': (intensidade / (2 * limites.escoreZ)).clamp(0.5, 1.0).toDouble(),
      // MAPE de 0% vale 1; de 50% ou mais, o mínimo.
      'Acerto da projeção (MAPE)':
          projecao.mape == null ? 0.6 : (1 - projecao.mape! / 50).clamp(0.3, 1.0).toDouble(),
    };

    return Alerta(
      id: '${indicador.id}-anomalia-${subiu ? 'alta' : 'queda'}-${Datas.iso(diaInicio)}',
      indicador: indicador,
      gravidade: intensidade >= 2 * limites.escoreZ ? Gravidade.critico : Gravidade.atencao,
      titulo: subiu ? '${indicador.nome} acima do padrão' : '${indicador.nome} abaixo do padrão',
      resumo: 'Média de ${valor(ultima.recentes.media)} nos últimos $diasRecentes dias, '
          '${Formato.variacao(variacao)} em relação ao normal do Centro. '
          'Fora do padrão desde ${Formato.dia(diaInicio)}.',
      evidencias: [
        'Média dos últimos $diasRecentes dias: ${valor(ultima.recentes.media)}.',
        'Padrão dos ${ultima.base.tamanho} dias anteriores: ${valor(ultima.base.media)} '
            '± ${valor(ultima.base.desvio)} por dia.',
        'Escore z da média = ${Formato.numero(escore)} (desvio ÷ √$diasRecentes; '
            'limite configurado: ${Formato.numero(limites.escoreZ)}).',
        'Fora do padrão ($direcao) há $diasNoEpisodio dia(s), desde ${Formato.dia(diaInicio)}.',
        'Projeção para amanhã (suavização exponencial): ${valor(projecao.proximoDia)}'
            '${projecao.mape == null ? '.' : ', com erro médio de ${Formato.numero(projecao.mape!)}% no histórico.'}',
      ],
      limitacoes: [
        ...Fundamentos.limitacoesDaFonte(serie, agora),
        if (ruido > 0.3)
          'Base muito variável (ruído de ${Formato.porcento(ruido)}): o desvio pode ser acaso.',
        if (ultima.base.tamanho < diasBase) 'Base com menos de $diasBase dias de histórico.',
        if ((projecao.mape ?? 0) > 15)
          'A projeção erra em média ${Formato.numero(projecao.mape!)}%: use-a só como referência.',
        'Feriados, eventos, obras e falhas de registro podem gerar desvios que não '
            'indicam um problema real.',
      ],
      qualidade: Fundamentos.qualidade(fatores, serie.origem),
      fatores: Fundamentos.comFonte(fatores, serie.origem),
      sugestao: Fundamentos.sugestao(indicador.id, queda: !subiu),
      dataReferencia: observados.last.dia,
      origem: serie.origem,
    );
  }

  /// Valores diários a partir dos quais a média de [diasRecentes] dias fica
  /// fora do padrão (base ± escoreZ × desvio ÷ √n). Usados no gráfico.
  static List<double> faixaDoPadrao(Serie serie, Limites limites) {
    final ultima = atual(serie);
    if (ultima == null) return const [];
    final margem = limites.escoreZ * ultima.base.desvio / math.sqrt(diasRecentes);
    final media = ultima.base.media;
    return switch (serie.indicador.sentido) {
      SentidoAnomalia.alta => [media + margem],
      SentidoAnomalia.baixa => [media - margem],
      SentidoAnomalia.ambos => [media - margem, media + margem],
    };
  }
}
