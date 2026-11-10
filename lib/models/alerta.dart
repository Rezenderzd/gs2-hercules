import 'indicador.dart';
import 'origem.dart';

enum Gravidade {
  atencao('Atenção'),
  critico('Crítico');

  const Gravidade(this.rotulo);

  final String rotulo;
}

/// Qualidade da evidência por trás de um alerta. Não é uma probabilidade:
/// resume a qualidade dos dados e do sinal (veja `fatores`).
enum NivelQualidade {
  baixa('baixa'),
  media('média'),
  alta('alta');

  const NivelQualidade(this.rotulo);

  final String rotulo;

  static NivelQualidade de(double valor) {
    if (valor >= 0.75) return NivelQualidade.alta;
    if (valor >= 0.5) return NivelQualidade.media;
    return NivelQualidade.baixa;
  }
}

/// Alerta gerado pelo `MotorAlertas`. Traz a justificativa ([evidencias]),
/// a qualidade da evidência e seus [fatores], as [limitacoes] e uma
/// sugestão. Nunca executa nada: a decisão é sempre de uma pessoa.
class Alerta {
  const Alerta({
    required this.id,
    required this.indicador,
    required this.gravidade,
    required this.titulo,
    required this.resumo,
    required this.evidencias,
    required this.limitacoes,
    required this.qualidade,
    required this.fatores,
    required this.sugestao,
    required this.dataReferencia,
    required this.origem,
  });

  /// Indicador + regra + primeiro dia do episódio: o mesmo enquanto o
  /// problema durar, para a decisão continuar ligada ao mesmo alerta.
  final String id;
  final Indicador indicador;
  final Gravidade gravidade;
  final String titulo;
  final String resumo;
  final List<String> evidencias;
  final List<String> limitacoes;

  /// Qualidade da evidência, de 0 a 1 (exibida como nota de 0 a 100).
  final double qualidade;
  final Map<String, double> fatores;
  final String sugestao;

  /// Dia do evento previsto ou do último dado observado.
  final DateTime dataReferencia;
  final Origem origem;

  RegraAlerta get regra => indicador.regra;

  NivelQualidade get nivelQualidade => NivelQualidade.de(qualidade);

  /// Nota de 0 a 100.
  int get notaQualidade => (qualidade * 100).round();
}
