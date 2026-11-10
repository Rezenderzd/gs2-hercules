import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/origem.dart';
import '../models/serie.dart';
import '../services/banco_local.dart';
import '../services/open_meteo_service.dart';
import '../services/simulador_service.dart';

class Leitura {
  const Leitura({required this.series, required this.lidaEm, this.aviso});

  final List<Serie> series;
  final DateTime lidaEm;

  final String? aviso;
}

class RepositorioTerritorio {
  RepositorioTerritorio({
    required OpenMeteoService openMeteo,
    required SimuladorService simulador,
    required BancoLocal banco,
  })  : _openMeteo = openMeteo,
        _simulador = simulador,
        _banco = banco;

  final OpenMeteoService _openMeteo;
  final SimuladorService _simulador;
  final BancoLocal _banco;

  static const _chaveClima = 'clima';

  Future<Leitura> carregar({DateTime? agora}) async {
    final momento = agora ?? DateTime.now();
    final (clima, cidade) = await (
      _carregarClima(momento),
      _simulador.buscarCidade(momento),
    ).wait;
    return Leitura(
      series: [...clima.series, ...cidade],
      lidaEm: momento,
      aviso: clima.aviso,
    );
  }

  void fechar() => _openMeteo.fechar();

  Future<({List<Serie> series, String? aviso})> _carregarClima(DateTime agora) async {
    final String motivo;
    try {
      final aoVivo = await _openMeteo.buscarClima(agora);
      await _salvarCache(aoVivo, agora);
      return (series: aoVivo, aviso: null);
    } on FalhaClima catch (falha) {
      motivo = falha.motivo.descricao;
    } catch (_) {
      motivo = MotivoFalhaClima.semConexao.descricao;
    }
    final cache = await _lerCache(agora);
    if (cache != null && cache.isNotEmpty) {
      return (series: cache, aviso: '$motivo: mostrando o último clima salvo.');
    }
    return (
      series: _simulador.climaReserva(agora),
      aviso: '$motivo e não há cache: o clima está com dados simulados.',
    );
  }

  Future<void> _salvarCache(List<Serie> series, DateTime agora) async {
    try {
      final db = await _banco.banco.timeout(const Duration(seconds: 4));
      await db.insert(
        BancoLocal.cache,
        {
          'chave': _chaveClima,
          'conteudo': jsonEncode(series.map((s) => s.paraMapa()).toList()),
          'salvo_em': agora.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<List<Serie>?> _lerCache(DateTime agora) async {
    try {
      final db = await _banco.banco.timeout(const Duration(seconds: 4));
      final linhas = await db.query(
        BancoLocal.cache,
        where: 'chave = ?',
        whereArgs: [_chaveClima],
        limit: 1,
      );
      if (linhas.isEmpty) return null;
      final salvoEm = DateTime.parse(linhas.first['salvo_em'] as String);
      final lista = jsonDecode(linhas.first['conteudo'] as String) as List<dynamic>;
      return lista
          .map((m) => Serie.deMapa(m as Map<String, dynamic>, origem: Origem.cache, atualizadaEm: salvoEm))
          .whereType<Serie>()
          .map((s) => s.comOrigem(Origem.cache, salvoEm, agora))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
