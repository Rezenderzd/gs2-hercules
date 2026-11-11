import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException, SupabaseClient;

import '../../models/sessao.dart';
import 'servico_nuvem.dart';

class NuvemSupabase implements ServicoNuvem {
  NuvemSupabase(this._cliente, {this.limite = const Duration(seconds: 8)});

  final SupabaseClient _cliente;
  final Duration limite;

  static const _codigosDadosRecusados = {'22023', '22P02', '23502', '23514'};

  @override
  Future<PerfilNuvem> entrar(String email, String chave) async {
    final resposta = await _chamar('entrar', {'p_email': email, 'p_chave': chave});
    final mapa = resposta is Map ? resposta : const {};
    return PerfilNuvem(
      titular: mapa['titular'] == true,
      gestorCadastrado: mapa['gestor'] == true,
    );
  }

  @override
  Future<bool> validarGestor(String email, String pin) async {
    final resposta = await _chamar('validar_gestor', {'p_email': email, 'p_pin': pin});
    return resposta == true;
  }

  @override
  Future<List<Map<String, dynamic>>> listarRelatos(String? email) async {
    return _linhas(await _chamar('listar_relatos', {'p_email': email}));
  }

  @override
  Future<void> registrarRelato(String email, Map<String, Object?> relato) async {
    await _chamar('registrar_relato', {
      'p_email': email,
      'p_id': relato['id'],
      'p_categoria': relato['categoria'],
      'p_bairro': relato['bairro'],
      'p_descricao': relato['descricao'],
      'p_urgencia': relato['urgencia'],
      'p_observado_em': relato['observado_em'],
      'p_criado_em': relato['criado_em'],
    });
  }

  @override
  Future<List<Map<String, dynamic>>> listarDecisoes(String? email) async {
    return _linhas(await _chamar('listar_decisoes', {'p_email': email}));
  }

  @override
  Future<void> decidir(Sessao sessao, Map<String, Object?> decisao) async {
    await _chamar('decidir', {
      'p_email': sessao.email,
      'p_pin': sessao.pin,
      'p_alerta_id': decisao['alerta_id'],
      'p_decisao': decisao['decisao'],
      'p_nota': decisao['nota'],
      'p_decidido_em': decisao['decidido_em'],
      'p_titulo': decisao['titulo_alerta'],
      'p_indicador': decisao['indicador'],
    });
  }

  @override
  Future<Map<String, dynamic>?> lerLimites() async {
    final resposta = await _chamar('ler_limites');
    return resposta is Map ? Map<String, dynamic>.from(resposta) : null;
  }

  @override
  Future<void> salvarLimites(Sessao sessao, Map<String, Object?> limites) async {
    await _chamar('salvar_limites', {
      'p_email': sessao.email,
      'p_pin': sessao.pin,
      'p_sensacao_c': limites['sensacaoC'],
      'p_uv': limites['uv'],
      'p_chuva_mm': limites['chuvaMm'],
      'p_escore_z': limites['escoreZ'],
    });
  }

  @override
  Future<void> apagarMeusDados(Sessao sessao) async {
    await _chamar('apagar_meus_dados', {'p_email': sessao.email, 'p_chave': sessao.chave});
  }

  Future<dynamic> _chamar(String funcao, [Map<String, dynamic>? parametros]) async {
    try {
      return await _cliente.rpc<dynamic>(funcao, params: parametros).timeout(limite);
    } on PostgrestException catch (erro) {
      debugPrint('[Supabase] $funcao: ${erro.code} ${erro.message}');
      final tipo = erro.code == '42501' || erro.message.contains('nao_autorizado')
          ? TipoFalhaNuvem.naoAutorizado
          : _codigosDadosRecusados.contains(erro.code)
              ? TipoFalhaNuvem.dadosRecusados
              : TipoFalhaNuvem.indisponivel;
      throw FalhaNuvem(tipo, '${erro.code} ${erro.message}');
    } on TimeoutException {
      debugPrint('[Supabase] $funcao: tempo esgotado');
      throw const FalhaNuvem(TipoFalhaNuvem.indisponivel, 'tempo esgotado');
    } catch (erro) {
      debugPrint('[Supabase] $funcao: $erro');
      throw FalhaNuvem(TipoFalhaNuvem.indisponivel, '$erro');
    }
  }

  static List<Map<String, dynamic>> _linhas(dynamic resposta) {
    if (resposta is! List) return const [];
    return [
      for (final linha in resposta)
        if (linha is Map) Map<String, dynamic>.from(linha),
    ];
  }
}
