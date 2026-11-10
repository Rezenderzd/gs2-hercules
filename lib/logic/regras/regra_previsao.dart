import 'dart:math' as math;

import '../../models/alerta.dart';
import '../../models/limites.dart';
import '../../models/ponto.dart';
import '../../models/serie.dart';
import '../../util/datas.dart';
import '../../util/formato.dart';
import 'fundamentos.dart';

/// Regra 1 — calor e clima: algum dia da previsão oficial (Open-Meteo)
/// atinge o limite definido pelos gestores.
class RegraPrevisao {
  const RegraPrevisao();

  /// Pico a partir do qual o alerta é crítico (15% acima do limite).
  static const double fatorCritico = 1.15;

  Alerta? avaliar(Serie serie, Limites limites, DateTime agora) {
    final limite = limites.limiteDe(serie.indicador.id);
    if (limite == null || limite <= 0) return null;

    final previstos = serie.previstos;
    final diasNoLimite = [for (final p in previstos) if (p.valor >= limite) p];
    if (diasNoLimite.isEmpty) return null;

    final primeiro = diasNoLimite.first;
    final pico = diasNoLimite.reduce((maior, p) => p.valor > maior.valor ? p : maior);
    final diasAteEvento = math.max(1, Datas.soDia(primeiro.dia).difference(Datas.soDia(agora)).inDays);
    final proporcao = pico.valor / limite;
    final indicador = serie.indicador;
    final unidade = indicador.unidade;
    String valor(double v) => '${Formato.numero(v, casas: indicador.casas)} $unidade';

    final fatores = {
      'Antecedência da previsão': (1 - 0.1 * (diasAteEvento - 1)).clamp(0.4, 1.0).toDouble(),
      'Margem sobre o limite': proporcao >= 1.05 ? 1.0 : 0.8,
    };

    return Alerta(
      // Primeiro dia previsto no limite: estável enquanto a previsão se mantiver.
      id: '${indicador.id}-previsao-${Datas.iso(primeiro.dia)}',
      indicador: indicador,
      gravidade: proporcao >= fatorCritico ? Gravidade.critico : Gravidade.atencao,
      titulo: '${indicador.nome} deve passar do limite',
      resumo: 'A previsão indica ${valor(pico.valor)} em ${_quando(pico)}. '
          'Há $diasAteEvento dia(s) para se preparar.',
      evidencias: [
        'Primeiro dia no limite: ${Formato.dia(primeiro.dia)}, com ${valor(primeiro.valor)} '
            '(limite de ${valor(limite)}).',
        'Pico previsto: ${valor(pico.valor)}, '
            '${Formato.variacao((proporcao - 1) * 100)} em relação ao limite.',
        '${diasNoLimite.length} de ${previstos.length} dias da previsão no limite ou acima.',
      ],
      limitacoes: [
        ...Fundamentos.limitacoesDaFonte(serie, agora),
        if (diasAteEvento > 3)
          'A previsão é para daqui a $diasAteEvento dias; quanto mais longe, maior a incerteza.',
        'Um único ponto de previsão representa todo o Centro; ruas e bairros podem variar.',
      ],
      qualidade: Fundamentos.qualidade(fatores, serie.origem),
      fatores: Fundamentos.comFonte(fatores, serie.origem),
      sugestao: Fundamentos.sugestao(indicador.id),
      dataReferencia: primeiro.dia,
      origem: serie.origem,
    );
  }

  static String _quando(Ponto p) => '${Formato.diaSemana(p.dia)}, ${Formato.dia(p.dia)}';
}
