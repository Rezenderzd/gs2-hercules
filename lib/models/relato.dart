import 'package:flutter/material.dart';

enum CategoriaRelato {
  lixoAcumulado('Lixo acumulado', Icons.delete_outline),
  entulho('Entulho na calçada', Icons.construction),
  onibusLotado('Ônibus lotado', Icons.directions_bus_outlined),
  semaforo('Semáforo com defeito', Icons.traffic_outlined),
  alagamento('Alagamento', Icons.water),
  outro('Outro', Icons.more_horiz);

  const CategoriaRelato(this.rotulo, this.icone);

  final String rotulo;
  final IconData icone;

  static CategoriaRelato porNome(String? nome) {
    return values.where((c) => c.name == nome).firstOrNull ?? CategoriaRelato.outro;
  }
}

enum Urgencia {
  baixa('Baixa'),
  media('Média'),
  alta('Alta');

  const Urgencia(this.rotulo);

  final String rotulo;

  static Urgencia porNome(String? nome) {
    return values.where((u) => u.name == nome).firstOrNull ?? Urgencia.media;
  }
}

class Relato {
  const Relato({
    required this.id,
    required this.categoria,
    required this.bairro,
    required this.descricao,
    required this.urgencia,
    required this.observadoEm,
    required this.criadoEm,
    this.meu = false,
    this.pendente = false,
  });

  factory Relato.deLinha(Map<String, Object?> linha) {
    return Relato(
      id: linha['id'] as String,
      categoria: CategoriaRelato.porNome(linha['categoria'] as String?),
      bairro: linha['bairro'] as String,
      descricao: linha['descricao'] as String,
      urgencia: Urgencia.porNome(linha['urgencia'] as String?),
      observadoEm: DateTime.parse(linha['observado_em'] as String).toLocal(),
      criadoEm: DateTime.parse(linha['criado_em'] as String).toLocal(),
      meu: _verdadeiro(linha['meu']),
      pendente: linha['sincronizado'] == 0,
    );
  }

  final String id;
  final CategoriaRelato categoria;
  final String bairro;
  final String descricao;
  final Urgencia urgencia;
  final DateTime observadoEm;
  final DateTime criadoEm;
  final bool meu;
  final bool pendente;

  Relato copiar({bool? meu, bool? pendente}) {
    return Relato(
      id: id,
      categoria: categoria,
      bairro: bairro,
      descricao: descricao,
      urgencia: urgencia,
      observadoEm: observadoEm,
      criadoEm: criadoEm,
      meu: meu ?? this.meu,
      pendente: pendente ?? this.pendente,
    );
  }

  Map<String, Object?> paraNuvem() => {
        'id': id,
        'categoria': categoria.name,
        'bairro': bairro,
        'descricao': descricao,
        'urgencia': urgencia.name,
        'observado_em': observadoEm.toUtc().toIso8601String(),
        'criado_em': criadoEm.toUtc().toIso8601String(),
      };

  Map<String, Object?> paraLinhaLocal({required bool sincronizado, String? autorEmail}) => {
        ...paraNuvem(),
        'meu': meu ? 1 : 0,
        'sincronizado': sincronizado ? 1 : 0,
        'autor_email': sincronizado ? null : autorEmail,
      };

  static bool _verdadeiro(Object? valor) => valor == true || valor == 1;
}

class RascunhoRelato {
  const RascunhoRelato({
    required this.categoria,
    required this.bairro,
    required this.descricao,
    required this.urgencia,
    required this.observadoEm,
  });

  final CategoriaRelato categoria;
  final String bairro;
  final String descricao;
  final Urgencia urgencia;
  final DateTime observadoEm;
}
