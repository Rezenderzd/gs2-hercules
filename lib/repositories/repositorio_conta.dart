import '../models/limites.dart';
import '../models/sessao.dart';
import '../services/nuvem/servico_nuvem.dart';

class RepositorioConta {
  RepositorioConta({ServicoNuvem? nuvem}) : _nuvem = nuvem;

  final ServicoNuvem? _nuvem;

  bool get usaNuvem => _nuvem != null;

  Future<PerfilNuvem> entrar(String email, String chave) async {
    final nuvem = _nuvem;
    if (nuvem == null) return const PerfilNuvem(titular: true, gestorCadastrado: true);
    return nuvem.entrar(email, chave);
  }

  Future<bool> validarGestor(String email, String pin) async {
    final nuvem = _nuvem;
    if (nuvem == null) return true;
    return nuvem.validarGestor(email, pin);
  }

  Future<Limites?> lerLimites() async {
    final mapa = await _nuvem?.lerLimites();
    return mapa == null ? null : Limites.deMapa(mapa);
  }

  Future<void> salvarLimites(Limites limites, Sessao sessao) async {
    await _nuvem?.salvarLimites(sessao, limites.paraMapa());
  }
}
