import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../logic/privacidade.dart';
import '../models/relato.dart';
import '../repositories/repositorio_relatos.dart';
import '../services/banco_local.dart';
import '../services/nuvem/servico_nuvem.dart';
import '../util/mensagens.dart';
import 'preferencias_store.dart';
import 'status_carga.dart';

class RelatosStore extends ChangeNotifier {
  RelatosStore({
    required RepositorioRelatos repositorio,
    required PreferenciasStore preferencias,
  })  : _repositorio = repositorio,
        _preferencias = preferencias;

  final RepositorioRelatos _repositorio;
  final PreferenciasStore _preferencias;
  final _aleatorio = math.Random();

  StatusCarga _status = StatusCarga.inicial;
  List<Relato> _relatos = const [];
  String? _aviso;
  bool _descartado = false;

  static const _limite = Duration(seconds: 20);

  static const _avisoSemNuvem =
      'Sem conexão com a nuvem agora. Mostrando a cópia deste aparelho; os relatos '
      'novos ficam guardados aqui e são enviados quando a conexão voltar.';

  StatusCarga get status => _status;
  List<Relato> get relatos => _relatos;
  bool get usaNuvem => _repositorio.usaNuvem;
  int get pendentes => _relatos.where((r) => r.pendente).length;

  String? get aviso => _aviso;

  Future<void> carregar() async {
    _status = StatusCarga.carregando;
    notifyListeners();
    try {
      final leitura = await _repositorio.listar(email: _preferencias.email).timeout(_limite);
      if (_descartado) return;
      final ids = {for (final r in leitura.relatos) r.id};
      final soNaMemoria = _relatos.where((r) => r.pendente && !ids.contains(r.id)).toList();
      _relatos = [...soNaMemoria, ...leitura.relatos];
      _aviso = leitura.nuvemIndisponivel ? _avisoSemNuvem : _avisoDePendentes();
    } on FalhaArmazenamento {
      if (_descartado) return;
      _aviso = Mensagens.semArmazenamento;
    } catch (_) {
      if (_descartado) return;
      _aviso = _avisoSemNuvem;
    }
    _status = StatusCarga.pronto;
    notifyListeners();
  }

  Future<bool> registrar(RascunhoRelato rascunho) async {
    final email = _preferencias.email;
    if (email == null) {
      throw const FalhaNuvem(TipoFalhaNuvem.naoAutorizado, 'sem e-mail');
    }
    final agora = DateTime.now();
    final relato = Relato(
      id: '${agora.microsecondsSinceEpoch}-${_aleatorio.nextInt(1 << 20)}',
      categoria: rascunho.categoria,
      bairro: rascunho.bairro,
      descricao: Privacidade.anonimizar(rascunho.descricao.trim()),
      urgencia: rascunho.urgencia,
      observadoEm: rascunho.observadoEm,
      criadoEm: agora,
      meu: true,
      pendente: usaNuvem,
    );
    _relatos = [relato, ..._relatos];
    _status = StatusCarga.pronto;
    notifyListeners();

    try {
      final enviado = await _repositorio.inserir(relato, email).timeout(_limite);
      _trocar(relato.copiar(pendente: !enviado));
      _aviso = enviado ? _avisoDePendentes() : _avisoSemNuvem;
      return enviado;
    } on FalhaNuvem catch (falha) {
      if (falha.tipo == TipoFalhaNuvem.indisponivel) {
        _aviso = _avisoSemNuvem;
        return false;
      }
      _relatos = _relatos.where((r) => r.id != relato.id).toList();
      rethrow;
    } on FalhaArmazenamento {
      _trocar(relato.copiar(pendente: true));
      _aviso = Mensagens.semArmazenamento;
      return false;
    } catch (_) {
      _trocar(relato.copiar(pendente: true));
      _aviso = _avisoSemNuvem;
      return false;
    } finally {
      if (!_descartado) notifyListeners();
    }
  }

  Map<CategoriaRelato, int> porCategoria() {
    final contagem = <CategoriaRelato, int>{};
    for (final r in _relatos) {
      contagem[r.categoria] = (contagem[r.categoria] ?? 0) + 1;
    }
    return contagem;
  }

  Future<void> apagarMeusDados() async {
    final sessao = _preferencias.sessao;
    if (sessao == null) return;
    await _repositorio.apagarMeusDados(sessao).timeout(_limite);
    _relatos = _relatos.where((r) => !r.meu).toList();
    _aviso = _avisoDePendentes();
    notifyListeners();
  }

  void _trocar(Relato atualizado) {
    _relatos = [
      for (final r in _relatos) r.id == atualizado.id ? atualizado : r,
    ];
  }

  String? _avisoDePendentes() {
    final n = pendentes;
    if (n == 0) return null;
    return n == 1
        ? '1 relato aguardando envio para a nuvem.'
        : '$n relatos aguardando envio para a nuvem.';
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
