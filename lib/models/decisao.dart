import 'package:flutter/material.dart';

enum Decisao {
  aguardando('Aguardando decisão', Icons.hourglass_top),
  emAnalise('Em análise', Icons.manage_search),
  aprovada('Aprovado', Icons.task_alt),
  recusada('Recusado', Icons.do_not_disturb_on_outlined);

  const Decisao(this.rotulo, this.icone);

  final String rotulo;
  final IconData icone;

  String get codigo => switch (this) {
        Decisao.aguardando => 'aguardando',
        Decisao.emAnalise => 'em_analise',
        Decisao.aprovada => 'aprovado',
        Decisao.recusada => 'recusado',
      };

  static Decisao porCodigo(String? codigo) {
    return values.where((d) => d.codigo == codigo).firstOrNull ?? Decisao.aguardando;
  }
}

class RegistroDecisao {
  const RegistroDecisao({
    required this.alertaId,
    required this.decisao,
    required this.nota,
    required this.quando,
    required this.tituloAlerta,
    required this.indicador,
    this.minha = false,
    this.pendente = false,
  });

  factory RegistroDecisao.deLinha(Map<String, Object?> linha) {
    return RegistroDecisao(
      alertaId: linha['alerta_id'] as String,
      decisao: Decisao.porCodigo(linha['decisao'] as String?),
      nota: linha['nota'] as String? ?? '',
      quando: DateTime.parse(linha['decidido_em'] as String).toLocal(),
      tituloAlerta: linha['titulo_alerta'] as String? ?? '',
      indicador: linha['indicador'] as String? ?? '',
      minha: linha['minha'] == true || linha['minha'] == 1,
      pendente: linha['sincronizado'] == 0,
    );
  }

  final String alertaId;
  final Decisao decisao;
  final String nota;
  final DateTime quando;
  final String tituloAlerta;
  final String indicador;
  final bool minha;
  final bool pendente;

  RegistroDecisao copiar({bool? pendente}) {
    return RegistroDecisao(
      alertaId: alertaId,
      decisao: decisao,
      nota: nota,
      quando: quando,
      tituloAlerta: tituloAlerta,
      indicador: indicador,
      minha: minha,
      pendente: pendente ?? this.pendente,
    );
  }

  Map<String, Object?> paraNuvem() => {
        'alerta_id': alertaId,
        'decisao': decisao.codigo,
        'nota': nota,
        'decidido_em': quando.toUtc().toIso8601String(),
        'titulo_alerta': tituloAlerta,
        'indicador': indicador,
      };

  Map<String, Object?> paraLinhaLocal({required bool sincronizado}) => {
        ...paraNuvem(),
        'minha': minha ? 1 : 0,
        'sincronizado': sincronizado ? 1 : 0,
      };
}
