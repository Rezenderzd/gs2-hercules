import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/limites.dart';
import '../models/sessao.dart';
import '../repositories/repositorio_conta.dart';
import '../services/preferencias_service.dart';

class PreferenciasStore extends ChangeNotifier {
  PreferenciasStore(PreferenciasService servico, {RepositorioConta? conta})
      : _servico = servico,
        _conta = conta ?? RepositorioConta(),
        _aceiteEm = servico.aceiteEm,
        _modoEscuro = servico.modoEscuro,
        _altoContraste = servico.altoContraste,
        _escalaFonte = servico.escalaFonte,
        _limites = servico.limites,
        _email = servico.email,
        _chave = servico.chaveAparelho,
        _titular = servico.titular,
        _pin = servico.pinGestor;

  final PreferenciasService _servico;
  final RepositorioConta _conta;

  static const double fonteMinima = 1.0;
  static const double fonteMaxima = 1.5;

  DateTime? _aceiteEm;
  bool _modoEscuro;
  bool _altoContraste;
  double _escalaFonte;
  Limites _limites;
  String? _email;
  String? _chave;
  bool? _titular;
  String? _pin;
  bool _gestorCadastrado = false;

  DateTime? get aceiteEm => _aceiteEm;
  bool get aceitou => _aceiteEm != null;
  bool get modoEscuro => _modoEscuro;
  bool get altoContraste => _altoContraste;
  double get escalaFonte => _escalaFonte;
  Limites get limites => _limites;
  bool get usaNuvem => _conta.usaNuvem;

  String? get email => _email;
  bool get entrou => _email != null;

  bool? get titular => _titular;

  bool get gestorCadastrado => _gestorCadastrado;

  bool get gestor => _pin != null;

  Sessao? get sessao {
    final email = _email;
    final chave = _chave;
    if (email == null || chave == null) return null;
    return Sessao(email: email, chave: chave, pin: _pin);
  }

  Future<void> entrar(String email) async {
    final normalizado = email.trim().toLowerCase();
    _chave = await _servico.criarChaveAparelho();
    await _servico.apagarConta();
    await _servico.salvarEmail(normalizado);
    _email = normalizado;
    _pin = null;
    _titular = null;
    _gestorCadastrado = false;
    notifyListeners();
    unawaited(confirmarConta());
  }

  Future<void> confirmarConta() async {
    final sessao = this.sessao;
    if (sessao == null) return;
    try {
      final perfil = await _conta.entrar(sessao.email, sessao.chave);
      if (_email != sessao.email) return;
      _titular = perfil.titular;
      _gestorCadastrado = perfil.gestorCadastrado;
      await _servico.salvarTitular(perfil.titular);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> entrarComoGestor(String pin) async {
    final email = _email;
    if (email == null) return false;
    final valido = await _conta.validarGestor(email, pin.trim());
    if (!valido) return false;
    _pin = pin.trim();
    await _servico.salvarPinGestor(_pin);
    notifyListeners();
    return true;
  }

  Future<void> sairDoGestor() async {
    _pin = null;
    await _servico.salvarPinGestor(null);
    notifyListeners();
  }

  Future<void> sair() async {
    await _servico.apagarConta();
    _email = null;
    _pin = null;
    _titular = null;
    _gestorCadastrado = false;
    notifyListeners();
  }

  Future<void> aceitar() async {
    final agora = DateTime.now();
    await _servico.salvarAceite(agora);
    _aceiteEm = agora;
    notifyListeners();
  }

  Future<void> revogar() async {
    await _servico.apagarAceite();
    await _servico.apagarConta();
    _aceiteEm = null;
    _email = null;
    _pin = null;
    _titular = null;
    _gestorCadastrado = false;
    notifyListeners();
  }

  Future<void> definirModoEscuro(bool ativo) async {
    if (ativo == _modoEscuro) return;
    _modoEscuro = ativo;
    notifyListeners();
    await _servico.salvarModoEscuro(ativo);
  }

  Future<void> definirAltoContraste(bool ativo) async {
    if (ativo == _altoContraste) return;
    _altoContraste = ativo;
    notifyListeners();
    await _servico.salvarAltoContraste(ativo);
  }

  Future<void> definirEscalaFonte(double escala) async {
    final valor = escala.clamp(fonteMinima, fonteMaxima).toDouble();
    if (valor == _escalaFonte) return;
    _escalaFonte = valor;
    notifyListeners();
    await _servico.salvarEscalaFonte(valor);
  }

  Future<void> definirLimites(Limites limites) async {
    if (limites == _limites) return;
    _limites = limites;
    notifyListeners();
    await _servico.salvarLimites(limites);
  }
}
