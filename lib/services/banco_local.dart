import 'package:sqflite/sqflite.dart';

import 'abrir_banco.dart';

typedef AbridorBanco = Future<Database> Function(String arquivo, OpenDatabaseOptions opcoes);

class BancoLocal {
  BancoLocal({this.arquivo = 'sao_paulo_atento.db', AbridorBanco? abridor})
      : _abridor = abridor ?? abrirBanco;

  final String arquivo;
  final AbridorBanco _abridor;

  static const int versao = 3;

  static const String relatos = 'relatos';
  static const String decisoes = 'decisoes';
  static const String cache = 'cache_series';

  Future<Database>? _banco;

  Future<Database> get banco {
    return _banco ??= _abridor(
      arquivo,
      OpenDatabaseOptions(version: versao, onCreate: _criarTabelas, onUpgrade: _atualizar),
    );
  }

  static Future<void> _atualizar(Database db, int de, int para) async {
    for (final tabela in [relatos, decisoes, cache]) {
      await db.execute('DROP TABLE IF EXISTS $tabela');
    }
    await _criarTabelas(db, para);
  }

  static Future<void> _criarTabelas(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE $relatos (
        id TEXT PRIMARY KEY NOT NULL,
        categoria TEXT NOT NULL,
        bairro TEXT NOT NULL,
        descricao TEXT NOT NULL,
        urgencia TEXT NOT NULL,
        observado_em TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        meu INTEGER NOT NULL DEFAULT 0,
        sincronizado INTEGER NOT NULL DEFAULT 1,
        autor_email TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $decisoes (
        alerta_id TEXT PRIMARY KEY NOT NULL,
        decisao TEXT NOT NULL,
        nota TEXT NOT NULL DEFAULT '',
        decidido_em TEXT NOT NULL,
        titulo_alerta TEXT NOT NULL,
        indicador TEXT NOT NULL,
        minha INTEGER NOT NULL DEFAULT 0,
        sincronizado INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE $cache (
        chave TEXT PRIMARY KEY NOT NULL,
        conteudo TEXT NOT NULL,
        salvo_em TEXT NOT NULL
      )
    ''');
  }
}

class FalhaArmazenamento implements Exception {
  const FalhaArmazenamento();

  @override
  String toString() => 'FalhaArmazenamento: o banco local não abriu';
}
