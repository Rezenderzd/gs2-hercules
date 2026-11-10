import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logic/privacidade.dart';
import '../models/limites.dart';

class PreferenciasService {
  PreferenciasService(this._prefs);

  final SharedPreferences _prefs;

  static const _aceiteEm = 'aceite_em';
  static const _modoEscuro = 'modo_escuro';
  static const _altoContraste = 'alto_contraste';
  static const _escalaFonte = 'escala_fonte';
  static const _limites = 'limites';
  static const _email = 'email';
  static const _chave = 'chave_aparelho';
  static const _titular = 'titular';
  static const _pin = 'pin_gestor';

  static const _codigoAntigo = 'codigo_anonimo';

  DateTime? get aceiteEm {
    final valor = _prefs.getString(_aceiteEm);
    return valor == null ? null : DateTime.tryParse(valor);
  }

  Future<void> salvarAceite(DateTime quando) async {
    await _prefs.setString(_aceiteEm, quando.toIso8601String());
  }

  Future<void> apagarAceite() async {
    await _prefs.remove(_aceiteEm);
    await _prefs.remove(_codigoAntigo);
  }

  String? get email => _prefs.getString(_email);

  Future<void> salvarEmail(String email) async {
    await _prefs.setString(_email, email);
  }

  Future<void> apagarConta() async {
    await _prefs.remove(_email);
    await _prefs.remove(_pin);
    await _prefs.remove(_titular);
  }

  String? get chaveAparelho => _prefs.getString(_chave);

  Future<String> criarChaveAparelho() async {
    final existente = chaveAparelho;
    if (existente != null) return existente;
    final nova = Privacidade.novaChaveAparelho();
    await _prefs.setString(_chave, nova);
    return nova;
  }

  bool? get titular => _prefs.getBool(_titular);

  Future<void> salvarTitular(bool titular) async {
    await _prefs.setBool(_titular, titular);
  }

  String? get pinGestor => _prefs.getString(_pin);

  Future<void> salvarPinGestor(String? pin) async {
    if (pin == null) {
      await _prefs.remove(_pin);
    } else {
      await _prefs.setString(_pin, pin);
    }
  }

  bool get modoEscuro => _prefs.getBool(_modoEscuro) ?? false;

  Future<void> salvarModoEscuro(bool ativo) async {
    await _prefs.setBool(_modoEscuro, ativo);
  }

  bool get altoContraste => _prefs.getBool(_altoContraste) ?? false;

  Future<void> salvarAltoContraste(bool ativo) async {
    await _prefs.setBool(_altoContraste, ativo);
  }

  double get escalaFonte => _prefs.getDouble(_escalaFonte) ?? 1.0;

  Future<void> salvarEscalaFonte(double escala) async {
    await _prefs.setDouble(_escalaFonte, escala);
  }

  Limites get limites {
    final valor = _prefs.getString(_limites);
    if (valor == null) return Limites.padrao;
    try {
      return Limites.deMapa(jsonDecode(valor) as Map<String, dynamic>);
    } catch (_) {
      return Limites.padrao;
    }
  }

  Future<void> salvarLimites(Limites limites) async {
    await _prefs.setString(_limites, jsonEncode(limites.paraMapa()));
  }
}
