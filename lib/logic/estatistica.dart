import 'dart:math' as math;

/// Um conjunto de valores de um indicador e as medidas que as regras usam.
/// As medidas são calculadas uma vez só, na primeira leitura.
class Amostra {
  Amostra(Iterable<double> valores) : valores = List.unmodifiable(valores);

  final List<double> valores;

  int get tamanho => valores.length;
  bool get vazia => valores.isEmpty;

  late final double media =
      vazia ? 0 : valores.fold<double>(0, (soma, v) => soma + v) / tamanho;

  /// Desvio padrão amostral (divide por n − 1).
  late final double desvio = tamanho < 2
      ? 0
      : math.sqrt(
          valores.fold<double>(0, (soma, v) => soma + (v - media) * (v - media)) / (tamanho - 1),
        );

  /// Ruído relativo (desvio ÷ média). Perto de 0 = série estável.
  double get variacaoRelativa => media.abs() < 1e-9 ? 0 : desvio / media.abs();

  /// Escore z da média de [recentes] em relação a esta amostra (a base).
  ///
  /// A média de n dias oscila menos que um dia isolado: o erro-padrão dela
  /// é desvio ÷ √n. Por isso o escore é (média recente − média da base) ÷
  /// (desvio da base ÷ √n). Positivo = acima do normal; negativo = abaixo.
  double escoreDaMedia(Amostra recentes) {
    if (recentes.vazia || desvio < 1e-9) return 0;
    final erroPadrao = desvio / math.sqrt(recentes.tamanho);
    return (recentes.media - media) / erroPadrao;
  }

  /// Quanto a média de [outra] variou em relação a esta, em %. `null` se a
  /// média desta for zero.
  double? variacaoPercentualPara(Amostra outra) {
    if (media.abs() < 1e-9) return null;
    return (outra.media / media - 1) * 100;
  }
}

/// Projeção do dia seguinte por suavização exponencial e o erro que ela
/// teria cometido no próprio histórico (MAPE), calculados numa só passada.
class Projecao {
  const Projecao._({required this.proximoDia, required this.mape});

  /// [alfa] é o peso do dia mais recente. O erro só começa a ser medido
  /// depois de [aquecimento] dias, para a suavização se estabilizar.
  factory Projecao.de(List<double> historico, {double alfa = 0.3, int aquecimento = 7}) {
    if (historico.isEmpty) return const Projecao._(proximoDia: 0, mape: null);
    var suavizado = historico.first;
    final errosRelativos = <double>[];
    for (var i = 1; i < historico.length; i++) {
      final real = historico[i];
      // Antes de incorporar o dia i, `suavizado` é a projeção para ele.
      if (i >= aquecimento && real.abs() > 1e-9) {
        errosRelativos.add(((suavizado - real) / real).abs());
      }
      suavizado = alfa * real + (1 - alfa) * suavizado;
    }
    return Projecao._(
      proximoDia: suavizado,
      mape: errosRelativos.isEmpty ? null : Amostra(errosRelativos).media * 100,
    );
  }

  final double proximoDia;

  /// Erro percentual absoluto médio da projeção de 1 dia; `null` com
  /// histórico curto.
  final double? mape;
}

/// Direção dos últimos dias em relação aos anteriores.
enum Direcao { subindo, estavel, caindo }

/// Tendência: média dos últimos [dias] contra a dos [dias] anteriores.
class Tendencia {
  const Tendencia._(this.variacao, this.direcao);

  /// `null` se não houver 2 × [dias] observações.
  static Tendencia? de(List<double> valores, {int dias = 7, double margem = 5}) {
    if (valores.length < dias * 2) return null;
    final atual = Amostra(valores.sublist(valores.length - dias));
    final anterior = Amostra(valores.sublist(valores.length - dias * 2, valores.length - dias));
    final variacao = anterior.variacaoPercentualPara(atual);
    if (variacao == null) return null;
    final direcao = variacao > margem
        ? Direcao.subindo
        : variacao < -margem
            ? Direcao.caindo
            : Direcao.estavel;
    return Tendencia._(variacao, direcao);
  }

  /// Variação em %.
  final double variacao;
  final Direcao direcao;
}
