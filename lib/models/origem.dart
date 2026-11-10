/// Procedência de uma série — sempre visível para quem usa o app.
enum Origem {
  aoVivo('Ao vivo', 1.0),
  cache('Cache local', 0.85),
  simulado('Simulado', 0.6);

  const Origem(this.rotulo, this.fatorQualidade);

  final String rotulo;

  /// Multiplicador aplicado à qualidade da evidência dos alertas.
  final double fatorQualidade;
}
