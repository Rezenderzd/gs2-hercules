enum Origem {
  aoVivo('Ao vivo', 1.0),
  cache('Cache local', 0.85),
  simulado('Simulado', 0.6);

  const Origem(this.rotulo, this.fatorQualidade);

  final String rotulo;

  final double fatorQualidade;
}
