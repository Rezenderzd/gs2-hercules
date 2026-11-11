import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';

import '../models/relato.dart';
import '../models/sessao.dart';
import '../services/banco_local.dart';
import '../services/nuvem/servico_nuvem.dart';

class LeituraRelatos {
  const LeituraRelatos(this.relatos, {this.nuvemIndisponivel = false});

  final List<Relato> relatos;

  final bool nuvemIndisponivel;
}

class RepositorioRelatos {
  RepositorioRelatos(this._banco, {ServicoNuvem? nuvem}) : _nuvem = nuvem;

  final BancoLocal _banco;
  final ServicoNuvem? _nuvem;

  static const Duration _limiteLocal = Duration(seconds: 3);

  bool get usaNuvem => _nuvem != null;

  Future<LeituraRelatos> listar({String? email}) async {
    final nuvem = _nuvem;
    if (nuvem == null) {
      final locais = await _lerLocal(email: email);
      if (locais == null) throw const FalhaArmazenamento();
      return LeituraRelatos(locais);
    }

    await enviarPendentes();
    try {
      final daNuvem = _converter(await nuvem.listarRelatos(email));
      await _substituirCopias(daNuvem);
      final idsNuvem = {for (final r in daNuvem) r.id};
      final pendentes = await _lerLocal(email: email, somentePendentes: true) ?? const <Relato>[];
      final todos = [
        ...daNuvem,
        ...pendentes.where((r) => !idsNuvem.contains(r.id)),
      ]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return LeituraRelatos(todos);
    } on FalhaNuvem {
      final locais = await _lerLocal(email: email);
      if (locais == null) rethrow;
      return LeituraRelatos(locais, nuvemIndisponivel: true);
    }
  }

  Future<bool> inserir(Relato relato, String email) async {
    final nuvem = _nuvem;
    final db = await _abrir();

    if (nuvem == null) {
      if (db == null) throw const FalhaArmazenamento();
      await db.insert(
        BancoLocal.relatos,
        relato.paraLinhaLocal(sincronizado: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    }

    if (db != null) {
      await db.insert(
        BancoLocal.relatos,
        relato.paraLinhaLocal(sincronizado: false, autorEmail: email),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    try {
      await nuvem.registrarRelato(email, relato.paraNuvem());
      if (db != null) await _marcarEnviado(db, relato.id);
      return true;
    } on FalhaNuvem catch (falha) {
      if (falha.tipo == TipoFalhaNuvem.indisponivel) {
        if (db == null) throw const FalhaArmazenamento();
        return false;
      }
      if (db != null) {
        await db.delete(BancoLocal.relatos, where: 'id = ?', whereArgs: [relato.id]);
      }
      rethrow;
    }
  }

  Future<int> enviarPendentes() async {
    final nuvem = _nuvem;
    if (nuvem == null) return 0;
    final db = await _abrir();
    if (db == null) return 0;

    final linhas = await db.query(BancoLocal.relatos, where: 'sincronizado = 0');
    var enviados = 0;
    for (final linha in linhas) {
      final relato = Relato.deLinha(linha);
      final email = linha['autor_email'] as String?;
      if (email == null) {
        await db.delete(BancoLocal.relatos, where: 'id = ?', whereArgs: [relato.id]);
        continue;
      }
      try {
        await nuvem.registrarRelato(email, relato.paraNuvem());
        await _marcarEnviado(db, relato.id);
        enviados++;
      } on FalhaNuvem catch (falha) {
        if (falha.tipo == TipoFalhaNuvem.indisponivel) break;
        debugPrint('[Relatos] ${relato.id} recusado pela nuvem e retirado da fila.');
        await db.delete(BancoLocal.relatos, where: 'id = ?', whereArgs: [relato.id]);
      }
    }
    return enviados;
  }

  Future<void> apagarMeusDados(Sessao sessao) async {
    await _nuvem?.apagarMeusDados(sessao);
    final db = await _abrir();
    if (db == null) return;
    await db.delete(
      BancoLocal.relatos,
      where: 'meu = 1 OR autor_email = ?',
      whereArgs: [sessao.email],
    );
  }

  Future<Database?> _abrir() async {
    try {
      return await _banco.banco.timeout(_limiteLocal);
    } catch (_) {
      return null;
    }
  }

  Future<void> _marcarEnviado(Database db, String id) async {
    await db.update(
      BancoLocal.relatos,
      {'sincronizado': 1, 'autor_email': null, 'meu': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _substituirCopias(List<Relato> daNuvem) async {
    final db = await _abrir();
    if (db == null) return;
    try {
      await db.transaction((txn) async {
        await txn.delete(BancoLocal.relatos, where: 'sincronizado = 1');
        for (final relato in daNuvem) {
          await txn.insert(
            BancoLocal.relatos,
            relato.paraLinhaLocal(sincronizado: true),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (erro) {
      debugPrint('[Relatos] cópia local não atualizada: $erro');
    }
  }

  Future<List<Relato>?> _lerLocal({String? email, bool somentePendentes = false}) async {
    final db = await _abrir();
    if (db == null) return null;
    try {
      final linhas = await db
          .query(
            BancoLocal.relatos,
            where: somentePendentes ? 'sincronizado = 0' : null,
            orderBy: 'criado_em DESC',
          )
          .timeout(_limiteLocal);
      return [
        for (final linha in linhas)
          if (linha['sincronizado'] == 0)
            Relato.deLinha(linha).copiar(meu: email != null && linha['autor_email'] == email)
          else
            Relato.deLinha(linha),
      ];
    } catch (_) {
      return null;
    }
  }

  static List<Relato> _converter(List<Map<String, dynamic>> linhas) {
    final relatos = <Relato>[];
    for (final linha in linhas) {
      try {
        relatos.add(Relato.deLinha(linha));
      } catch (erro) {
        debugPrint('[Relatos] linha ignorada (${linha['id']}): $erro');
      }
    }
    return relatos;
  }
}
