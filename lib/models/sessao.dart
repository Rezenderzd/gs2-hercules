class Sessao {
  const Sessao({required this.email, required this.chave, this.pin});

  final String email;
  final String chave;
  final String? pin;

  bool get gestor => pin != null;
}
