import 'dart:math' as math;

class Amostra {
  Amostra(Iterable<double> valores) : valores = List.unmodifiable(valores);

  final List<double> valores;

  int get tamanho => valores.length;
  bool get vazia => valores.isEmpty;

  late final double media =
      vazia ? 0 : valores.fold<double>(0, (soma, v) => soma + v) / tamanho;

  late final double desvio = tamanho < 2
      ? 0
      : math.sqrt(
          valores.fold<double>(0, (soma, v) => soma + (v - media) * (v - media)) / (tamanho - 1),
        );

  double get variacaoRelativa => media.abs() < 1e-9 ? 0 : desvio / media.abs();

  double escoreDaMedia(Amostra recentes) {
    if (recentes.vazia || desvio < 1e-9) return 0;
    final erroPadrao = desvio / math.sqrt(recentes.tamanho);
    return (recentes.media - media) / erroPadrao;
  }

  double? variacaoPercentualPara(Amostra outra) {
    if (media.abs() < 1e-9) return null;
    return (outra.media / media - 1) * 100;
  }
}

class Projecao {
  const Projecao._({required this.proximoDia, required this.mape});

  factory Projecao.de(List<double> historico, {double alfa = 0.3, int aquecimento = 7}) {
    if (historico.isEmpty) return const Projecao._(proximoDia: 0, mape: null);
    var suavizado = historico.first;
    final errosRelativos = <double>[];
    for (var i = 1; i < historico.length; i++) {
      final real = historico[i];
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

  final double? mape;
}

enum Direcao { subindo, estavel, caindo }

class Tendencia {
  const Tendencia._(this.variacao, this.direcao);

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

  final double variacao;
  final Direcao direcao;
}
