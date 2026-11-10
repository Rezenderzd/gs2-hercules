/// Valor diário de um indicador. [previsto] marca os dias futuros.
class Ponto {
  const Ponto({required this.dia, required this.valor, this.previsto = false});

  factory Ponto.deMapa(Map<String, dynamic> mapa) {
    return Ponto(
      dia: DateTime.parse(mapa['dia'] as String),
      valor: (mapa['valor'] as num).toDouble(),
      previsto: mapa['previsto'] as bool? ?? false,
    );
  }

  final DateTime dia;
  final double valor;
  final bool previsto;

  Map<String, Object?> paraMapa() => {
        'dia': dia.toIso8601String(),
        'valor': valor,
        'previsto': previsto,
      };
}
