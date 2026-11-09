import 'package:flutter/material.dart';

/// Paleta enxuta do São Paulo Atento, distribuída como `ThemeExtension`
/// (Aula 18). Uma única cor de destaque; as cores de estado aparecem só em
/// pequenos pontos, para não poluir a tela.
@immutable
class Cores extends ThemeExtension<Cores> {
  const Cores({
    required this.brilho,
    required this.fundo,
    required this.cartao,
    required this.linha,
    required this.texto,
    required this.suave,
    required this.destaque,
    required this.sobreDestaque,
    required this.ok,
    required this.atencao,
    required this.critico,
  });

  final Brightness brilho;
  final Color fundo;
  final Color cartao;
  final Color linha;
  final Color texto;
  final Color suave;
  final Color destaque;
  final Color sobreDestaque;
  final Color ok;
  final Color atencao;
  final Color critico;

  static Cores de(BuildContext context) => Theme.of(context).extension<Cores>() ?? claro;

  /// Modo claro (padrão). Texto e cores de destaque com contraste ≥ 4,5:1.
  static const claro = Cores(
    brilho: Brightness.light,
    fundo: Color(0xFFFAFAF9),
    cartao: Color(0xFFFFFFFF),
    linha: Color(0xFFE7E5E4),
    texto: Color(0xFF1C1917),
    suave: Color(0xFF6B6560),
    destaque: Color(0xFF047857),
    sobreDestaque: Color(0xFFFFFFFF),
    ok: Color(0xFF15803D),
    atencao: Color(0xFFB45309),
    critico: Color(0xFFB91C1C),
  );

  /// Modo escuro, opcional em Ajustes.
  static const escuro = Cores(
    brilho: Brightness.dark,
    fundo: Color(0xFF0C0A09),
    cartao: Color(0xFF1C1917),
    linha: Color(0xFF292524),
    texto: Color(0xFFFAFAF9),
    suave: Color(0xFFA8A29E),
    destaque: Color(0xFF34D399),
    sobreDestaque: Color(0xFF022C22),
    ok: Color(0xFF4ADE80),
    atencao: Color(0xFFFBBF24),
    critico: Color(0xFFF87171),
  );

  /// Alto contraste, claro: texto preto e cores escuras (contraste ≥ 7:1).
  static const altoContrasteClaro = Cores(
    brilho: Brightness.light,
    fundo: Color(0xFFFFFFFF),
    cartao: Color(0xFFFFFFFF),
    linha: Color(0xFF1C1917),
    texto: Color(0xFF000000),
    suave: Color(0xFF292524),
    destaque: Color(0xFF064E3B),
    sobreDestaque: Color(0xFFFFFFFF),
    ok: Color(0xFF14532D),
    atencao: Color(0xFF7C2D12),
    critico: Color(0xFF7F1D1D),
  );

  /// Alto contraste, escuro: texto branco sobre preto (contraste ≥ 7:1).
  static const altoContrasteEscuro = Cores(
    brilho: Brightness.dark,
    fundo: Color(0xFF000000),
    cartao: Color(0xFF000000),
    linha: Color(0xFFF5F5F4),
    texto: Color(0xFFFFFFFF),
    suave: Color(0xFFE7E5E4),
    destaque: Color(0xFF6EE7B7),
    sobreDestaque: Color(0xFF000000),
    ok: Color(0xFF86EFAC),
    atencao: Color(0xFFFCD34D),
    critico: Color(0xFFFCA5A5),
  );

  /// Paleta para a combinação de modo escuro e alto contraste.
  static Cores para({required bool escuro, required bool altoContraste}) {
    if (altoContraste) return escuro ? altoContrasteEscuro : altoContrasteClaro;
    return escuro ? Cores.escuro : claro;
  }

  @override
  Cores copyWith({
    Brightness? brilho,
    Color? fundo,
    Color? cartao,
    Color? linha,
    Color? texto,
    Color? suave,
    Color? destaque,
    Color? sobreDestaque,
    Color? ok,
    Color? atencao,
    Color? critico,
  }) {
    return Cores(
      brilho: brilho ?? this.brilho,
      fundo: fundo ?? this.fundo,
      cartao: cartao ?? this.cartao,
      linha: linha ?? this.linha,
      texto: texto ?? this.texto,
      suave: suave ?? this.suave,
      destaque: destaque ?? this.destaque,
      sobreDestaque: sobreDestaque ?? this.sobreDestaque,
      ok: ok ?? this.ok,
      atencao: atencao ?? this.atencao,
      critico: critico ?? this.critico,
    );
  }

  @override
  Cores lerp(ThemeExtension<Cores>? other, double t) {
    if (other is! Cores) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return Cores(
      brilho: t < 0.5 ? brilho : other.brilho,
      fundo: m(fundo, other.fundo),
      cartao: m(cartao, other.cartao),
      linha: m(linha, other.linha),
      texto: m(texto, other.texto),
      suave: m(suave, other.suave),
      destaque: m(destaque, other.destaque),
      sobreDestaque: m(sobreDestaque, other.sobreDestaque),
      ok: m(ok, other.ok),
      atencao: m(atencao, other.atencao),
      critico: m(critico, other.critico),
    );
  }
}
