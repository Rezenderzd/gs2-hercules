import '../../models/origem.dart';
import '../../models/serie.dart';
import '../../util/formato.dart';
import '../estatistica.dart';

/// Partes comuns às duas regras de alerta.
abstract final class Fundamentos {
  /// Nome do fator ligado à procedência dos dados.
  static const fatorFonte = 'Fonte dos dados';

  /// Qualidade da evidência: média dos [fatores] × peso da fonte, entre 5%
  /// e 95% (nenhum alerta é "certeza").
  static double qualidade(Map<String, double> fatores, Origem origem) {
    final media = Amostra(fatores.values).media;
    return (media * origem.fatorQualidade).clamp(0.05, 0.95).toDouble();
  }

  /// Os fatores exibidos na tela: os da regra e o da fonte.
  static Map<String, double> comFonte(Map<String, double> fatores, Origem origem) {
    return {...fatores, fatorFonte: origem.fatorQualidade};
  }

  /// O que a procedência dos dados limita na análise.
  static List<String> limitacoesDaFonte(Serie serie, DateTime agora) {
    final idadeCache = agora.difference(serie.atualizadaEm);
    return switch (serie.origem) {
      Origem.aoVivo => const [],
      Origem.simulado => const [
          'Dados simulados: demonstram o método, mas não descrevem o território real.',
        ],
      Origem.cache => [
          'Dados do cache de ${Formato.dataHora(serie.atualizadaEm)}; podem estar desatualizados.',
          if (idadeCache.inHours > 24)
            'O cache tem mais de 24 horas: confirme a informação antes de decidir.',
        ],
    };
  }

  /// Sugestão para a equipe. [queda] distingue a falta de coleta do excesso.
  static String sugestao(String indicadorId, {bool queda = false}) {
    if (indicadorId == 'coleta') {
      return queda
          ? 'Verificar com a concessionária se houve falha na coleta (rota, frota ou '
              'paralisação) e programar a recuperação.'
          : 'Avaliar reforço de rota e de frequência da coleta nos bairros afetados.';
    }
    return switch (indicadorId) {
      'sensacao' => 'Avaliar pontos de hidratação e atenção redobrada a idosos e '
          'pessoas em situação de rua.',
      'uv' => 'Avaliar comunicado sobre proteção solar e horários de menor exposição.',
      'chuva' => 'Avaliar limpeza preventiva de bocas de lobo e contato com a Defesa Civil.',
      'lotacao' => 'Avaliar com a SPTrans o reforço de frota nos horários de pico.',
      'tempo_viagem' => 'Avaliar obras e desvios que estejam atrasando as linhas.',
      'sinistros' => 'Avaliar fiscalização e sinalização nos cruzamentos com mais ocorrências.',
      'descarte' => 'Avaliar mutirão de limpeza e fiscalização nos pontos de descarte recorrente.',
      _ => 'Avaliar a situação com a equipe responsável.',
    };
  }
}
