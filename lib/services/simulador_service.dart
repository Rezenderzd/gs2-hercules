import 'dart:math' as math;

import '../models/indicador.dart';
import '../models/origem.dart';
import '../models/ponto.dart';
import '../models/serie.dart';
import '../util/datas.dart';

class SimuladorService {
  const SimuladorService({this.atraso = const Duration(milliseconds: 400)});

  final Duration atraso;

  static const int diasHistorico = 30;
  static const int _diasPico = 3;

  Future<List<Serie>> buscarCidade(DateTime agora) async {
    await Future<void>.delayed(atraso);
    return [
      _gerar(Indicadores.lotacao, agora, semente: 7, base: 72, ruido: 4, pico: 0.1),
      _gerar(Indicadores.tempoViagem, agora, semente: 13, base: 48, ruido: 3, fimDeSemana: 0.8),
      _gerar(Indicadores.sinistros, agora, semente: 19, base: 6, ruido: 1.5, pico: 0.9),
      _gerar(Indicadores.coleta, agora, semente: 29, base: 95, ruido: 5, fimDeSemana: 0.85),
      _gerar(Indicadores.descarte, agora, semente: 31, base: 14, ruido: 2.5, pico: 0.3),
    ];
  }

  List<Serie> climaReserva(DateTime agora) {
    return [
      _gerar(Indicadores.sensacao, agora, semente: 41, base: 28, ruido: 1.5, previsao: 7, fixos: const {3: 35}),
      _gerar(Indicadores.uv, agora, semente: 43, base: 10, ruido: 1.5, previsao: 7),
      _gerar(Indicadores.chuva, agora, semente: 47, base: 6, ruido: 0, previsao: 7, chuvoso: true, fixos: const {2: 55}),
    ];
  }

  Serie _gerar(
    Indicador indicador,
    DateTime agora, {
    required int semente,
    required double base,
    required double ruido,
    double fimDeSemana = 1,
    double pico = 0,
    int previsao = 0,
    bool chuvoso = false,
    Map<int, double> fixos = const {},
  }) {
    final hoje = Datas.soDia(agora);
    final pontos = <Ponto>[];

    for (var deslocamento = 1 - diasHistorico; deslocamento <= previsao; deslocamento++) {
      final dia = Datas.somarDias(hoje, deslocamento);
      final sorteio = math.Random(semente * 100003 + Datas.diaEpoca(dia));
      final ehFimDeSemana = dia.weekday >= DateTime.saturday;

      double valor;
      if (chuvoso) {
        valor = sorteio.nextDouble() < 0.55 ? 0.0 : sorteio.nextDouble() * base * 4;
      } else {
        valor = base * (ehFimDeSemana ? fimDeSemana : 1) + (sorteio.nextDouble() * 2 - 1) * ruido;
      }
      if (deslocamento > -_diasPico && deslocamento <= 0) valor *= 1 + pico;
      valor = fixos[deslocamento] ?? valor;

      pontos.add(Ponto(dia: dia, valor: valor < 0 ? 0.0 : valor, previsto: deslocamento > 0));
    }

    return Serie(indicador: indicador, pontos: pontos, origem: Origem.simulado, atualizadaEm: agora);
  }
}
