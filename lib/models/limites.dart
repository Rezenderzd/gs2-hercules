/// Faixa aceita por um limite configurável (usada na validação).
class Faixa {
  const Faixa(this.minimo, this.maximo);

  final double minimo;
  final double maximo;

  bool contem(double v) => v >= minimo && v <= maximo;
}

/// Limites que disparam alertas. Definidos por pessoas em Ajustes.
class Limites {
  const Limites({
    required this.sensacaoC,
    required this.uv,
    required this.chuvaMm,
    required this.escoreZ,
  });

  factory Limites.deMapa(Map<String, dynamic> mapa) {
    double ler(String chave, double padrao) {
      return (mapa[chave] as num?)?.toDouble() ?? padrao;
    }

    return Limites(
      sensacaoC: ler('sensacaoC', padrao.sensacaoC),
      uv: ler('uv', padrao.uv),
      chuvaMm: ler('chuvaMm', padrao.chuvaMm),
      escoreZ: ler('escoreZ', padrao.escoreZ),
    );
  }

  static const padrao = Limites(sensacaoC: 33, uv: 11, chuvaMm: 40, escoreZ: 2);

  static const faixaSensacao = Faixa(30, 50);
  static const faixaUv = Faixa(3, 15);
  static const faixaChuva = Faixa(10, 200);
  static const faixaEscoreZ = Faixa(1.5, 4);

  /// Sensação térmica máxima prevista (°C).
  final double sensacaoC;

  /// Índice UV máximo previsto.
  final double uv;

  /// Chuva prevista em um dia (mm).
  final double chuvaMm;

  /// Quantos desvios padrão acima do normal caracterizam uma anomalia.
  final double escoreZ;

  /// Limite absoluto dos indicadores avaliados por previsão.
  double? limiteDe(String indicadorId) {
    return switch (indicadorId) {
      'sensacao' => sensacaoC,
      'uv' => uv,
      'chuva' => chuvaMm,
      _ => null,
    };
  }

  Map<String, Object?> paraMapa() => {
        'sensacaoC': sensacaoC,
        'uv': uv,
        'chuvaMm': chuvaMm,
        'escoreZ': escoreZ,
      };

  @override
  bool operator ==(Object other) {
    return other is Limites &&
        other.sensacaoC == sensacaoC &&
        other.uv == uv &&
        other.chuvaMm == chuvaMm &&
        other.escoreZ == escoreZ;
  }

  @override
  int get hashCode => Object.hash(sensacaoC, uv, chuvaMm, escoreZ);
}
