/// Espaçamentos e raios do Design System (Aula 17). Pouca variedade de
/// medidas = layout mais calmo.
abstract final class Espacos {
  static const double minimo = 4;
  static const double pequeno = 8;

  /// Entre itens de uma lista de cartões.
  static const double entre = 12;
  static const double medio = 16;
  static const double grande = 24;
  static const double enorme = 40;

  /// Margem lateral das telas.
  static const double margem = 20;

  static const double raio = 16;

  /// Largura máxima do conteúdo em tablets e no navegador.
  static const double larguraMaxima = 680;

  /// Área mínima de toque (acessibilidade).
  static const double toque = 48;

  /// Altura dos botões principais.
  static const double botao = 52;

  /// Tamanho do indicador de progresso dentro de um botão.
  static const double progressoBotao = 20;
}
