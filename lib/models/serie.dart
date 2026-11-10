import '../util/datas.dart';
import 'indicador.dart';
import 'origem.dart';
import 'ponto.dart';

class Serie {
  const Serie({
    required this.indicador,
    required this.pontos,
    required this.origem,
    required this.atualizadaEm,
  });

  final Indicador indicador;
  final List<Ponto> pontos;
  final Origem origem;
  final DateTime atualizadaEm;

  List<Ponto> get observados => pontos.where((p) => !p.previsto).toList();

  List<Ponto> get previstos => pontos.where((p) => p.previsto).toList();

  List<double> get valoresObservados => observados.map((p) => p.valor).toList();

  Ponto? get ultimo => observados.lastOrNull;

  List<Ponto> recorte(int dias) {
    final obs = observados;
    final inicio = obs.length > dias ? obs.length - dias : 0;
    return [...obs.sublist(inicio), ...previstos];
  }

  Serie comOrigem(Origem novaOrigem, DateTime quando, DateTime agora) {
    final hoje = Datas.soDia(agora);
    return Serie(
      indicador: indicador,
      pontos: pontos.where((p) => !p.previsto || p.dia.isAfter(hoje)).toList(),
      origem: novaOrigem,
      atualizadaEm: quando,
    );
  }

  Map<String, Object?> paraMapa() => {
        'indicador': indicador.id,
        'pontos': pontos.map((p) => p.paraMapa()).toList(),
      };

  static Serie? deMapa(
    Map<String, dynamic> mapa, {
    required Origem origem,
    required DateTime atualizadaEm,
  }) {
    final indicador = Indicadores.porId(mapa['indicador'] as String? ?? '');
    if (indicador == null) return null;
    final pontos = (mapa['pontos'] as List<dynamic>? ?? const [])
        .map((p) => Ponto.deMapa(p as Map<String, dynamic>))
        .toList();
    return Serie(
      indicador: indicador,
      pontos: pontos,
      origem: origem,
      atualizadaEm: atualizadaEm,
    );
  }
}
