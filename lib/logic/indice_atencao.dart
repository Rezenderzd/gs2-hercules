import '../models/indicador.dart';
import '../models/limites.dart';
import '../models/serie.dart';
import 'estatistica.dart';
import 'regras/regra_anomalia.dart';

/// Faixas do Índice de Atenção.
enum NivelAtencao {
  tranquilo('Tranquilo', 0),
  atencao('Atenção', 40),
  alto('Alto', 70);

  const NivelAtencao(this.rotulo, this.piso);

  final String rotulo;

  /// Menor índice da faixa.
  final double piso;

  static NivelAtencao de(double indice) {
    return values.lastWhere((nivel) => indice >= nivel.piso, orElse: () => tranquilo);
  }
}

/// Quanto um indicador está pressionado, de 0 (normal) a 100.
class Pressao {
  const Pressao({required this.indicador, required this.valor});

  final Indicador indicador;
  final double valor;

  /// Previsão: o maior valor entre hoje e os próximos 3 dias, em relação ao
  /// limite. Vale 0 em 60% do limite e 100 no limite.
  static double? daPrevisao(Serie serie, Limites limites) {
    final limite = limites.limiteDe(serie.indicador.id);
    if (limite == null || limite <= 0) return null;
    final proximos = [
      if (serie.ultimo case final hoje?) hoje.valor,
      for (final p in serie.previstos.take(3)) p.valor,
    ];
    if (proximos.isEmpty) return null;
    final maior = proximos.reduce((a, b) => b > a ? b : a);
    return ((maior / limite - 0.6) / 0.4 * 100).clamp(0.0, 100.0).toDouble();
  }

  /// Anomalia: 30 com a média no padrão, 70 quando o escore atinge o limite
  /// configurado (é quando nasce o alerta). Só conta o sentido que importa
  /// para o indicador.
  static double? daAnomalia(Serie serie, Limites limites) {
    final escore = RegraAnomalia.atual(serie)?.escore;
    if (escore == null) return null;
    final relevante = switch (serie.indicador.sentido) {
      SentidoAnomalia.alta => escore > 0 ? escore : 0.0,
      SentidoAnomalia.baixa => escore < 0 ? -escore : 0.0,
      SentidoAnomalia.ambos => escore.abs(),
    };
    return (30 + 40 * relevante / limites.escoreZ).clamp(0.0, 100.0).toDouble();
  }

  static Pressao? de(Serie serie, Limites limites) {
    final valor = switch (serie.indicador.regra) {
      RegraAlerta.limitePrevisto => daPrevisao(serie, limites),
      RegraAlerta.anomalia => daAnomalia(serie, limites),
    };
    return valor == null ? null : Pressao(indicador: serie.indicador, valor: valor);
  }
}

/// Índice de Atenção (0–100): a média simples das pressões. Transparente e
/// fácil de conferir; o detalhe de cada indicador fica no painel.
abstract final class IndiceAtencao {
  static List<Pressao> pressoes(List<Serie> series, Limites limites) {
    return [
      for (final serie in series)
        if (Pressao.de(serie, limites) case final pressao?) pressao,
    ];
  }

  static double geral(List<Pressao> pressoes) {
    return Amostra(pressoes.map((p) => p.valor)).media;
  }
}
