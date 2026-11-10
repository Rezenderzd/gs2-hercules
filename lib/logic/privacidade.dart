import 'dart:math' as math;

abstract final class Privacidade {
  static const String marcador = '[removido]';

  static final RegExp _cpf = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');

  static final RegExp _telefone = RegExp(
    r'(?:\+?55\s?)?(?:\(?\b[1-9]{2}\)?[\s-]?9?\d{4}[\s.-]?\d{4}|\b9?\d{4}[\s.-]\d{4})\b',
  );

  static String anonimizar(String texto) {
    return texto
        .replaceAll(_cpf, marcador)
        .replaceAll(_email, marcador)
        .replaceAll(_telefone, marcador);
  }

  static bool temDadoPessoal(String texto) {
    return _cpf.hasMatch(texto) || _email.hasMatch(texto) || _telefone.hasMatch(texto);
  }

  static String novaChaveAparelho([math.Random? aleatorio]) {
    final gerador = aleatorio ?? math.Random.secure();
    return List.generate(32, (_) => gerador.nextInt(16).toRadixString(16)).join();
  }
}
