import 'package:flutter_test/flutter_test.dart';
import 'package:sao_paulo_atento/models/decisao.dart';
import 'package:sao_paulo_atento/models/relato.dart';
import 'package:sao_paulo_atento/models/sessao.dart';
import 'package:sao_paulo_atento/repositories/repositorio_decisoes.dart';
import 'package:sao_paulo_atento/repositories/repositorio_relatos.dart';
import 'package:sao_paulo_atento/services/banco_local.dart';
import 'package:sao_paulo_atento/services/nuvem/servico_nuvem.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class NuvemFalsa implements ServicoNuvem {
  bool online = true;
  final relatos = <String, ({String email, Map<String, Object?> dados})>{};
  final decisoes = <String, Map<String, Object?>>{};
  final chaves = <String, String>{};
  final gestores = <String, String>{'gestor@exemplo.com': '1234'};

  void _exigirConexao() {
    if (!online) throw const FalhaNuvem(TipoFalhaNuvem.indisponivel, 'offline');
  }

  @override
  Future<PerfilNuvem> entrar(String email, String chave) async {
    _exigirConexao();
    chaves.putIfAbsent(email, () => chave);
    return PerfilNuvem(titular: chaves[email] == chave, gestorCadastrado: gestores.containsKey(email));
  }

  @override
  Future<bool> validarGestor(String email, String pin) async {
    _exigirConexao();
    return gestores[email] == pin;
  }

  @override
  Future<List<Map<String, dynamic>>> listarRelatos(String? email) async {
    _exigirConexao();
    return [
      for (final r in relatos.values) {...r.dados, 'meu': r.email == email},
    ];
  }

  @override
  Future<void> registrarRelato(String email, Map<String, Object?> relato) async {
    _exigirConexao();
    relatos.putIfAbsent(relato['id']! as String, () => (email: email, dados: relato));
  }

  @override
  Future<List<Map<String, dynamic>>> listarDecisoes(String? email) async {
    _exigirConexao();
    return [for (final d in decisoes.values) {...d, 'minha': false}];
  }

  @override
  Future<void> decidir(Sessao sessao, Map<String, Object?> decisao) async {
    _exigirConexao();
    if (gestores[sessao.email] != sessao.pin) {
      throw const FalhaNuvem(TipoFalhaNuvem.naoAutorizado, 'não é gestor');
    }
    decisoes[decisao['alerta_id']! as String] = decisao;
  }

  @override
  Future<Map<String, dynamic>?> lerLimites() async => null;

  @override
  Future<void> salvarLimites(Sessao sessao, Map<String, Object?> limites) async {}

  @override
  Future<void> apagarMeusDados(Sessao sessao) async {
    _exigirConexao();
    if (chaves[sessao.email] != sessao.chave) {
      throw const FalhaNuvem(TipoFalhaNuvem.naoAutorizado, 'outro aparelho');
    }
    relatos.removeWhere((_, r) => r.email == sessao.email);
    chaves.remove(sessao.email);
  }
}

BancoLocal novoBanco() {
  return BancoLocal(
    abridor: (_, opcoes) => databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: opcoes.version,
        onCreate: opcoes.onCreate,
        onUpgrade: opcoes.onUpgrade,
        singleInstance: false,
      ),
    ),
  );
}

Relato relato(String id) {
  final agora = DateTime.now();
  return Relato(
    id: id,
    categoria: CategoriaRelato.lixoAcumulado,
    bairro: 'Sé',
    descricao: 'Lixo acumulado na esquina da praça há dias',
    urgencia: Urgencia.media,
    observadoEm: agora,
    criadoEm: agora,
    meu: true,
  );
}

RegistroDecisao decisao(String alertaId) {
  return RegistroDecisao(
    alertaId: alertaId,
    decisao: Decisao.aprovada,
    nota: '',
    quando: DateTime.now(),
    tituloAlerta: 'Alerta de teste',
    indicador: 'Lotação',
    minha: true,
  );
}

void main() {
  setUpAll(sqfliteFfiInit);

  const ana = Sessao(email: 'ana@exemplo.com', chave: 'chave-do-aparelho-a-0001');
  const gestor = Sessao(email: 'gestor@exemplo.com', chave: 'chave-do-aparelho-g-0001', pin: '1234');

  group('RepositorioRelatos', () {
    test('relato feito sem conexão fica pendente e sobe quando a conexão volta', () async {
      final nuvem = NuvemFalsa()..online = false;
      final repo = RepositorioRelatos(novoBanco(), nuvem: nuvem);

      expect(await repo.inserir(relato('r1'), ana.email), isFalse);
      final offline = await repo.listar(email: ana.email);
      expect(offline.nuvemIndisponivel, isTrue);
      expect(offline.relatos.single.pendente, isTrue);

      nuvem.online = true;
      final online = await repo.listar(email: ana.email);
      expect(nuvem.relatos.keys, ['r1']);
      expect(online.relatos.single.pendente, isFalse);
      expect(online.relatos.single.meu, isTrue);
    });

    test('relato apagado na nuvem não volta pela cópia de outro aparelho', () async {
      final nuvem = NuvemFalsa();
      await nuvem.entrar(ana.email, ana.chave);
      final aparelhoA = RepositorioRelatos(novoBanco(), nuvem: nuvem);
      final aparelhoB = RepositorioRelatos(novoBanco(), nuvem: nuvem);

      await aparelhoA.inserir(relato('r1'), ana.email);
      expect((await aparelhoB.listar()).relatos, hasLength(1));

      await aparelhoA.apagarMeusDados(ana);
      expect(nuvem.relatos, isEmpty);

      final depois = await aparelhoB.listar();
      expect(depois.relatos, isEmpty);
      expect(nuvem.relatos, isEmpty);
    });

    test('só o aparelho titular apaga os dados do e-mail', () async {
      final nuvem = NuvemFalsa();
      await nuvem.entrar(ana.email, ana.chave);
      final repo = RepositorioRelatos(novoBanco(), nuvem: nuvem);
      await repo.inserir(relato('r1'), ana.email);

      const impostor = Sessao(email: 'ana@exemplo.com', chave: 'outra-chave-qualquer-99');
      await expectLater(
        repo.apagarMeusDados(impostor),
        throwsA(isA<FalhaNuvem>().having((f) => f.tipo, 'tipo', TipoFalhaNuvem.naoAutorizado)),
      );
      expect(nuvem.relatos, hasLength(1));
    });

    test('sem nuvem, o SQLite é a única fonte', () async {
      final repo = RepositorioRelatos(novoBanco());
      expect(await repo.inserir(relato('r1'), ana.email), isTrue);
      final leitura = await repo.listar(email: ana.email);
      expect(leitura.relatos.single.id, 'r1');
      expect(leitura.relatos.single.pendente, isFalse);
    });
  });

  group('RepositorioDecisoes', () {
    test('decisão sem conexão não se perde na leitura seguinte e sobe depois', () async {
      final nuvem = NuvemFalsa()..online = false;
      final repo = RepositorioDecisoes(novoBanco(), nuvem: nuvem);

      expect(await repo.salvar(decisao('a1'), gestor), isFalse);

      nuvem.online = true;
      final semGestor = await repo.carregar();
      expect(semGestor['a1']?.pendente, isTrue);

      final comGestor = await repo.carregar(sessao: gestor);
      expect(nuvem.decisoes.keys, ['a1']);
      expect(comGestor['a1']?.pendente, isFalse);
    });

    test('quem não é gestor não decide', () async {
      final repo = RepositorioDecisoes(novoBanco(), nuvem: NuvemFalsa());
      await expectLater(
        repo.salvar(decisao('a1'), ana),
        throwsA(isA<FalhaNuvem>().having((f) => f.tipo, 'tipo', TipoFalhaNuvem.naoAutorizado)),
      );
    });

    test('decisões da nuvem substituem as cópias antigas', () async {
      final nuvem = NuvemFalsa();
      final repo = RepositorioDecisoes(novoBanco(), nuvem: nuvem);
      await repo.salvar(decisao('a1'), gestor);
      expect((await repo.carregar()).keys, ['a1']);

      nuvem.decisoes.clear();
      expect(await repo.carregar(), isEmpty);
    });
  });
}
