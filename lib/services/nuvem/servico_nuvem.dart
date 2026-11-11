import '../../models/sessao.dart';

enum TipoFalhaNuvem {
  indisponivel,

  naoAutorizado,

  dadosRecusados,
}

class FalhaNuvem implements Exception {
  const FalhaNuvem(this.tipo, [this.detalhe = '']);

  final TipoFalhaNuvem tipo;

  final String detalhe;

  @override
  String toString() => 'FalhaNuvem(${tipo.name}): $detalhe';
}

class PerfilNuvem {
  const PerfilNuvem({required this.titular, required this.gestorCadastrado});

  final bool titular;

  final bool gestorCadastrado;
}

abstract interface class ServicoNuvem {
  Future<PerfilNuvem> entrar(String email, String chave);

  Future<bool> validarGestor(String email, String pin);

  Future<List<Map<String, dynamic>>> listarRelatos(String? email);

  Future<void> registrarRelato(String email, Map<String, Object?> relato);

  Future<List<Map<String, dynamic>>> listarDecisoes(String? email);

  Future<void> decidir(Sessao sessao, Map<String, Object?> decisao);

  Future<Map<String, dynamic>?> lerLimites();

  Future<void> salvarLimites(Sessao sessao, Map<String, Object?> limites);

  Future<void> apagarMeusDados(Sessao sessao);
}
