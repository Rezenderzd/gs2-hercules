/// Quem está usando o app neste momento.
///
/// Não há senha nem confirmação de e-mail (decisão do projeto). A [chave] é
/// um código aleatório gerado uma vez por aparelho: o primeiro aparelho que
/// usa um e-mail fica como titular e só ele pode apagar os dados daquele
/// e-mail. O [pin] só existe para gestores validados.
class Sessao {
  const Sessao({required this.email, required this.chave, this.pin});

  final String email;
  final String chave;
  final String? pin;

  bool get gestor => pin != null;
}
