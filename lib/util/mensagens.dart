import '../services/banco_local.dart';
import '../services/nuvem/servico_nuvem.dart';

abstract final class Mensagens {
  static const semConexao = 'Sem conexão com o banco agora. Tente de novo em instantes.';

  static const semArmazenamento = 'Este navegador não conseguiu abrir o armazenamento do app. '
      'Pare o app, rode "dart run sqflite_common_ffi_web:setup" e abra de novo.';

  static String deFalha(Object erro, {required String acao}) {
    if (erro is FalhaNuvem) {
      return switch (erro.tipo) {
        TipoFalhaNuvem.indisponivel => semConexao,
        TipoFalhaNuvem.naoAutorizado => 'Você não tem permissão para $acao.',
        TipoFalhaNuvem.dadosRecusados =>
          'O banco recusou os dados. Confira os campos e tente de novo.',
      };
    }
    if (erro is FalhaArmazenamento) return semArmazenamento;
    return 'Não foi possível $acao agora. Tente de novo.';
  }
}
