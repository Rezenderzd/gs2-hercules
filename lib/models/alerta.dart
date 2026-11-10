import 'indicador.dart';
import 'origem.dart';

enum Gravidade {
  atencao('Atenção'),
  critico('Crítico');

  const Gravidade(this.rotulo);

  final String rotulo;
}

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

  final String id;
  final Indicador indicador;
  final Gravidade gravidade;
  final String titulo;
  final String resumo;
  final List<String> evidencias;
  final List<String> limitacoes;

  final double qualidade;
  final Map<String, double> fatores;
  final String sugestao;

  final DateTime dataReferencia;
  final Origem origem;

  RegraAlerta get regra => indicador.regra;

  NivelQualidade get nivelQualidade => NivelQualidade.de(qualidade);

  int get notaQualidade => (qualidade * 100).round();
}
