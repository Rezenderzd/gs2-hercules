import '../models/alerta.dart';
import '../models/indicador.dart';
import '../models/limites.dart';
import '../models/serie.dart';
import 'regras/regra_anomalia.dart';
import 'regras/regra_previsao.dart';

/// Linha de referência desenhada no gráfico de um indicador.
class Referencia {
  const Referencia(this.valores, this.rotulo);

  final List<double> valores;
  final String rotulo;
}

/// Gera os alertas do território. Não faz I/O: recebe as séries e os
/// limites e devolve alertas explicáveis, ordenados por gravidade e pela
/// qualidade da evidência. Cada indicador usa uma das duas regras
/// (`RegraPrevisao` ou `RegraAnomalia`).
class MotorAlertas {
  const MotorAlertas();

  static const _previsao = RegraPrevisao();
  static const _anomalia = RegraAnomalia();

  List<Alerta> avaliar({
    required List<Serie> series,
    required Limites limites,
    required DateTime agora,
  }) {
    final alertas = [
      for (final serie in series)
        if (_avaliar(serie, limites, agora) case final alerta?) alerta,
    ];
    alertas.sort((a, b) {
      final porGravidade = b.gravidade.index.compareTo(a.gravidade.index);
      return porGravidade != 0 ? porGravidade : b.qualidade.compareTo(a.qualidade);
    });
    return alertas;
  }

  /// Escore z da média recente; `null` com histórico curto ou em
  /// indicadores avaliados por previsão.
  double? escoreRecente(Serie serie) {
    if (serie.indicador.regra != RegraAlerta.anomalia) return null;
    return RegraAnomalia.atual(serie)?.escore;
  }

  /// Linha(s) de referência do gráfico: o limite absoluto (clima) ou a
  /// faixa a partir da qual a média recente fica fora do padrão.
  Referencia? referencia(Serie serie, Limites limites) {
    switch (serie.indicador.regra) {
      case RegraAlerta.limitePrevisto:
        final limite = limites.limiteDe(serie.indicador.id);
        return limite == null ? null : Referencia([limite], 'limite');
      case RegraAlerta.anomalia:
        final faixa = RegraAnomalia.faixaDoPadrao(serie, limites);
        return faixa.isEmpty ? null : Referencia(faixa, 'fora do padrão (média de ${RegraAnomalia.diasRecentes} dias)');
    }
  }

  Alerta? _avaliar(Serie serie, Limites limites, DateTime agora) {
    return switch (serie.indicador.regra) {
      RegraAlerta.limitePrevisto => _previsao.avaliar(serie, limites, agora),
      RegraAlerta.anomalia => _anomalia.avaliar(serie, limites, agora),
    };
  }
}
