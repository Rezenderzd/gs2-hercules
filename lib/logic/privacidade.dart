import 'dart:math' as math;

/// Proteção de dados pessoais (LGPD) aplicada antes de gravar qualquer texto.
abstract final class Privacidade {
  static const String marcador = '[removido]';

  static final RegExp _cpf = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');

  /// Telefone brasileiro: com DDD (10 ou 11 dígitos, com ou sem separador)
  /// ou sem DDD, mas com separador ("99876-5432"). Oito dígitos seguidos,
  /// como um número de protocolo, não contam como telefone.
  static final RegExp _telefone = RegExp(
    r'(?:\+?55\s?)?(?:\(?\b[1-9]{2}\)?[\s-]?9?\d{4}[\s.-]?\d{4}|\b9?\d{4}[\s.-]\d{4})\b',
  );

  /// Troca CPF, e-mail e telefone por [marcador].
  static String anonimizar(String texto) {
    return texto
        .replaceAll(_cpf, marcador)
        .replaceAll(_email, marcador)
        .replaceAll(_telefone, marcador);
  }

  static bool temDadoPessoal(String texto) {
    return _cpf.hasMatch(texto) || _email.hasMatch(texto) || _telefone.hasMatch(texto);
  }

  /// Chave aleatória do aparelho (32 caracteres hexadecimais). Não
  /// identifica a pessoa: serve para provar que um pedido de exclusão vem
  /// do mesmo aparelho que usou o e-mail pela primeira vez.
  static String novaChaveAparelho([math.Random? aleatorio]) {
    final gerador = aleatorio ?? math.Random.secure();
    return List.generate(32, (_) => gerador.nextInt(16).toRadixString(16)).join();
  }
}
