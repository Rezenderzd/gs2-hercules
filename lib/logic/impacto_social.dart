import '../config/territorio.dart';
import '../models/alerta.dart';
import '../models/decisao.dart';
import '../models/indicador.dart';
import '../util/datas.dart';
import 'estatistica.dart';

/// Indicadores de benefício social: ligam o desempenho dos alertas ao que
/// eles significam para quem vive no território.
class ImpactoSocial {
  const ImpactoSocial({
    required this.moradores,
    required this.alertas,
    required this.decididos,
    required this.antecedenciaMedia,
    required this.relatos,
  });

  factory ImpactoSocial.calcular({
    required List<Alerta> alertas,
    required Map<String, RegistroDecisao> decisoes,
    required int relatos,
    required DateTime agora,
  }) {
    final decididos = alertas.where((a) {
      final decisao = decisoes[a.id]?.decisao ?? Decisao.aguardando;
      return decisao != Decisao.aguardando;
    }).length;

    final hoje = Datas.soDia(agora);
    final antecedencias = alertas
        .where((a) => a.regra == RegraAlerta.limitePrevisto)
        .map((a) => Datas.soDia(a.dataReferencia).difference(hoje).inDays.toDouble())
        .where((dias) => dias > 0)
        .toList();

    return ImpactoSocial(
      moradores: Territorio.moradoresEstimados,
      alertas: alertas.length,
      decididos: decididos,
      antecedenciaMedia:
          antecedencias.isEmpty ? null : Amostra(antecedencias).media,
      relatos: relatos,
    );
  }

  final int moradores;
  final int alertas;
  final int decididos;

  /// Dias, em média, entre o alerta e o evento previsto.
  final double? antecedenciaMedia;
  final int relatos;

  double get taxaDecisao => alertas == 0 ? 0.0 : decididos / alertas;
}
