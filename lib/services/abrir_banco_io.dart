import 'dart:io' show Platform;

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

Future<Database> abrirBanco(String arquivo, OpenDatabaseOptions opcoes) {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    ffi.sqfliteFfiInit();
    return ffi.databaseFactoryFfi.openDatabase(arquivo, options: opcoes);
  }
  return openDatabase(
    arquivo,
    version: opcoes.version,
    onCreate: opcoes.onCreate,
    onUpgrade: opcoes.onUpgrade,
  );
}
