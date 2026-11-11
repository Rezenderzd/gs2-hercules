import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';

import '../models/decisao.dart';
import '../models/sessao.dart';
import '../services/banco_local.dart';
import '../services/nuvem/servico_nuvem.dart';

class RepositorioDecisoes {
  RepositorioDecisoes(this._banco, {ServicoNuvem? nuvem}) : _nuvem = nuvem;

  final BancoLocal _banco;
  final ServicoNuvem? _nuvem;

  static const Duration _limiteLocal = Duration(seconds: 3);

  bool get usaNuvem => _nuvem != null;

  Future<Map<String, RegistroDecisao>> carregar({Sessao? sessao}) async {
    final nuvem = _nuvem;
    if (nuvem == null) {
      final locais = await _lerLocal();
      if (locais == null) throw const FalhaArmazenamento();
      return _porAlerta(locais);
    }

    await enviarPendentes(sessao);
    try {
      final daNuvem = _converter(await nuvem.listarDecisoes(sessao?.email));
      await _substituirCopias(daNuvem);
      final pendentes = await _lerLocal(somentePendentes: true) ?? const <RegistroDecisao>[];
      return {..._porAlerta(daNuvem), ..._porAlerta(pendentes)};
    } on FalhaNuvem {
      final locais = await _lerLocal();
      if (locais == null) rethrow;
      return _porAlerta(locais);
    }
  }

  Future<bool> salvar(RegistroDecisao registro, Sessao? sessao) async {
    final nuvem = _nuvem;
    final db = await _abrir();

    if (nuvem == null) {
      if (db == null) throw const FalhaArmazenamento();
      await _gravar(db, registro, sincronizado: true);
      return true;
    }
    if (sessao == null || !sessao.gestor) {
      throw const FalhaNuvem(TipoFalhaNuvem.naoAutorizado, 'sessão sem gestor');
    }

    if (db != null) await _gravar(db, registro, sincronizado: false);
    try {
      await nuvem.decidir(sessao, registro.paraNuvem());
      if (db != null) await _marcarEnviada(db, registro.alertaId);
      return true;
    } on FalhaNuvem catch (falha) {
      if (falha.tipo == TipoFalhaNuvem.indisponivel) {
        if (db == null) throw const FalhaArmazenamento();
        return false;
      }
      if (db != null) {
        await db.delete(BancoLocal.decisoes, where: 'alerta_id = ?', whereArgs: [registro.alertaId]);
      }
      rethrow;
    }
  }

  Future<int> enviarPendentes(Sessao? sessao) async {
    final nuvem = _nuvem;
    if (nuvem == null || sessao == null || !sessao.gestor) return 0;
    final db = await _abrir();
    if (db == null) return 0;

    final linhas = await db.query(BancoLocal.decisoes, where: 'sincronizado = 0');
    var enviadas = 0;
    for (final linha in linhas) {
      final registro = RegistroDecisao.deLinha(linha);
      try {
        await nuvem.decidir(sessao, registro.paraNuvem());
        await _marcarEnviada(db, registro.alertaId);
        enviadas++;
      } on FalhaNuvem catch (falha) {
        if (falha.tipo == TipoFalhaNuvem.indisponivel) break;
        debugPrint('[Decisões] ${registro.alertaId} recusada pela nuvem e retirada da fila.');
        await db.delete(BancoLocal.decisoes, where: 'alerta_id = ?', whereArgs: [registro.alertaId]);
      }
    }
    return enviadas;
  }

  Future<Database?> _abrir() async {
    try {
      return await _banco.banco.timeout(_limiteLocal);
    } catch (_) {
      return null;
    }
  }

  Future<void> _gravar(Database db, RegistroDecisao registro, {required bool sincronizado}) async {
    await db.insert(
      BancoLocal.decisoes,
      registro.paraLinhaLocal(sincronizado: sincronizado),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _marcarEnviada(Database db, String alertaId) async {
    await db.update(
      BancoLocal.decisoes,
      {'sincronizado': 1},
      where: 'alerta_id = ?',
      whereArgs: [alertaId],
    );
  }

  Future<void> _substituirCopias(List<RegistroDecisao> daNuvem) async {
    final db = await _abrir();
    if (db == null) return;
    try {
      await db.transaction((txn) async {
        await txn.delete(BancoLocal.decisoes, where: 'sincronizado = 1');
        for (final registro in daNuvem) {
          await txn.insert(
            BancoLocal.decisoes,
            registro.paraLinhaLocal(sincronizado: true),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });
    } catch (erro) {
      debugPrint('[Decisões] cópia local não atualizada: $erro');
    }
  }

  Future<List<RegistroDecisao>?> _lerLocal({bool somentePendentes = false}) async {
    final db = await _abrir();
    if (db == null) return null;
    try {
      final linhas = await db
          .query(BancoLocal.decisoes, where: somentePendentes ? 'sincronizado = 0' : null)
          .timeout(_limiteLocal);
      return linhas.map(RegistroDecisao.deLinha).toList();
    } catch (_) {
      return null;
    }
  }

  static Map<String, RegistroDecisao> _porAlerta(List<RegistroDecisao> registros) {
    return {for (final r in registros) r.alertaId: r};
  }

  static List<RegistroDecisao> _converter(List<Map<String, dynamic>> linhas) {
    final registros = <RegistroDecisao>[];
    for (final linha in linhas) {
      try {
        registros.add(RegistroDecisao.deLinha(linha));
      } catch (erro) {
        debugPrint('[Decisões] linha ignorada (${linha['alerta_id']}): $erro');
      }
    }
    return registros;
  }
}
