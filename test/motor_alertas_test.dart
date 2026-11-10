import 'package:flutter_test/flutter_test.dart';
import 'package:sao_paulo_atento/logic/impacto_social.dart';
import 'package:sao_paulo_atento/logic/indice_atencao.dart';
import 'package:sao_paulo_atento/logic/motor_alertas.dart';
import 'package:sao_paulo_atento/models/alerta.dart';
import 'package:sao_paulo_atento/models/decisao.dart';
import 'package:sao_paulo_atento/models/indicador.dart';
import 'package:sao_paulo_atento/models/limites.dart';
import 'package:sao_paulo_atento/models/origem.dart';
import 'package:sao_paulo_atento/models/ponto.dart';
import 'package:sao_paulo_atento/models/serie.dart';
import 'package:sao_paulo_atento/util/datas.dart';

final agora = DateTime(2026, 11, 8, 9);
const motor = MotorAlertas();
const limites = Limites.padrao;

Serie serie(
  Indicador indicador, {
  required List<double> observados,
  List<double> previstos = const [],
  Origem origem = Origem.aoVivo,
  DateTime? em,
}) {
  final hoje = Datas.soDia(em ?? agora);
  return Serie(
    indicador: indicador,
    origem: origem,
    atualizadaEm: agora,
    pontos: [
      for (var i = 0; i < observados.length; i++)
        Ponto(dia: Datas.somarDias(hoje, i - observados.length + 1), valor: observados[i]),
      for (var i = 0; i < previstos.length; i++)
        Ponto(dia: Datas.somarDias(hoje, i + 1), valor: previstos[i], previsto: true),
    ],
  );
}

List<double> comPico(double a, double b, double pico, {int base = 24}) => [
      for (var i = 0; i < base; i++) i.isEven ? a : b,
      pico,
      pico,
      pico,
    ];

void main() {
  group('Regra de previsão acima do limite', () {
    test('gera alerta com evidências, confiança e limitações', () {
      final alertas = motor.avaliar(
        series: [serie(Indicadores.sensacao, observados: List.filled(30, 30), previstos: [32, 34, 33])],
        limites: limites,
        agora: agora,
      );

      expect(alertas, hasLength(1));
      final alerta = alertas.single;
      expect(alerta.id, 'sensacao-previsao-2026-11-10');
      expect(alerta.gravidade, Gravidade.atencao);
      expect(alerta.evidencias, isNotEmpty);
      expect(alerta.limitacoes, isNotEmpty);
      expect(alerta.qualidade, inInclusiveRange(0.05, 0.95));
      expect(alerta.fatores, contains('Fonte dos dados'));
    });

    test('sem alerta quando a previsão fica abaixo do limite', () {
      final alertas = motor.avaliar(
        series: [serie(Indicadores.chuva, observados: List.filled(30, 5), previstos: [10, 20])],
        limites: limites,
        agora: agora,
      );
      expect(alertas, isEmpty);
    });

    test('pico 15% acima do limite é crítico', () {
      final alerta = motor
          .avaliar(
            series: [serie(Indicadores.chuva, observados: List.filled(30, 5), previstos: [60])],
            limites: limites,
            agora: agora,
          )
          .single;
      expect(alerta.gravidade, Gravidade.critico);
    });

    test('dados simulados reduzem a qualidade da evidência e viram limitação', () {
      Alerta gerar(Origem origem) => motor
          .avaliar(
            series: [
              serie(Indicadores.uv, observados: List.filled(30, 9), previstos: [12], origem: origem),
            ],
            limites: limites,
            agora: agora,
          )
          .single;

      final aoVivo = gerar(Origem.aoVivo);
      final simulado = gerar(Origem.simulado);
      expect(simulado.qualidade, lessThan(aoVivo.qualidade));
      expect(simulado.limitacoes.any((t) => t.contains('simulados')), isTrue);
    });
  });

  group('Regra de anomalia (escore z da média)', () {
    test('subida acima de z = 2 gera alerta de atenção', () {
      final alertas = motor.avaliar(
        series: [serie(Indicadores.descarte, observados: comPico(10, 12, 12.5))],
        limites: limites,
        agora: agora,
      );
      expect(alertas, hasLength(1));
      expect(alertas.single.gravidade, Gravidade.atencao);
      expect(alertas.single.evidencias.join(' '), contains('Escore z'));
      expect(alertas.single.fatores, contains('Acerto da projeção (MAPE)'));
    });

    test('o id usa o primeiro dia do episódio e não muda no dia seguinte', () {
      final hoje = motor
          .avaliar(
            series: [serie(Indicadores.descarte, observados: comPico(10, 12, 12.5))],
            limites: limites,
            agora: agora,
          )
          .single;
      final amanha = agora.add(const Duration(days: 1));
      final diaSeguinte = motor
          .avaliar(
            series: [
              serie(Indicadores.descarte, observados: [...comPico(10, 12, 12.5), 12.5], em: amanha),
            ],
            limites: limites,
            agora: amanha,
          )
          .single;
      expect(hoje.id, 'descarte-anomalia-alta-2026-11-07');
      expect(diaSeguinte.id, hoje.id);
    });

    test('escore com o dobro do limite é crítico', () {
      final alerta = motor
          .avaliar(
            series: [serie(Indicadores.sinistros, observados: comPico(5, 7, 12))],
            limites: limites,
            agora: agora,
          )
          .single;
      expect(alerta.gravidade, Gravidade.critico);
    });

    test('sem alerta quando o recente está dentro do padrão', () {
      final alertas = motor.avaliar(
        series: [serie(Indicadores.coleta, observados: comPico(90, 100, 96))],
        limites: limites,
        agora: agora,
      );
      expect(alertas, isEmpty);
    });

    test('queda na coleta gera alerta (os dois sentidos contam)', () {
      final alerta = motor
          .avaliar(
            series: [serie(Indicadores.coleta, observados: comPico(90, 100, 80))],
            limites: limites,
            agora: agora,
          )
          .single;
      expect(alerta.id, contains('queda'));
      expect(alerta.titulo, contains('abaixo do padrão'));
    });

    test('queda em indicador que só olha subidas não gera alerta', () {
      final alertas = motor.avaliar(
        series: [serie(Indicadores.descarte, observados: comPico(10, 12, 8))],
        limites: limites,
        agora: agora,
      );
      expect(alertas, isEmpty);
    });

    test('a faixa do padrão da coleta tem as duas linhas', () {
      final referencia = motor.referencia(serie(Indicadores.coleta, observados: comPico(90, 100, 96)), limites);
      expect(referencia!.valores, hasLength(2));
      expect(referencia.rotulo, contains('fora do padrão'));
    });

    test('histórico curto não é avaliado', () {
      expect(motor.escoreRecente(serie(Indicadores.lotacao, observados: [70, 71, 90])), isNull);
    });

    test('críticos aparecem primeiro', () {
      final alertas = motor.avaliar(
        series: [
          serie(Indicadores.descarte, observados: comPico(10, 12, 12.5)),
          serie(Indicadores.sinistros, observados: comPico(5, 7, 12)),
        ],
        limites: limites,
        agora: agora,
      );
      expect(alertas.first.gravidade, Gravidade.critico);
    });
  });

  group('Índice de Atenção', () {
    test('previsão no limite vale 100 e em 60% do limite vale 0', () {
      final noLimite = serie(Indicadores.chuva, observados: [0], previstos: [40]);
      final longe = serie(Indicadores.chuva, observados: [24], previstos: [10]);
      expect(Pressao.de(noLimite, limites)!.valor, closeTo(100, 1e-9));
      expect(Pressao.de(longe, limites)!.valor, closeTo(0, 1e-9));
    });

    test('anomalia: média no padrão vale 30', () {
      final estavel = serie(Indicadores.coleta, observados: List.filled(27, 95));
      expect(Pressao.de(estavel, limites)!.valor, closeTo(30, 1e-9));
    });

    test('anomalia: queda não pressiona indicador que só olha subidas', () {
      final queda = serie(Indicadores.descarte, observados: comPico(10, 12, 8));
      expect(Pressao.de(queda, limites)!.valor, closeTo(30, 1e-9));
    });

    test('nível do índice', () {
      expect(NivelAtencao.de(20), NivelAtencao.tranquilo);
      expect(NivelAtencao.de(55), NivelAtencao.atencao);
      expect(NivelAtencao.de(80), NivelAtencao.alto);
    });
  });

  test('impacto social: antecedência e taxa de decisão', () {
    final alertas = motor.avaliar(
      series: [
        serie(Indicadores.sensacao, observados: List.filled(30, 30), previstos: [32, 34]),
        serie(Indicadores.descarte, observados: comPico(10, 12, 13.5)),
      ],
      limites: limites,
      agora: agora,
    );
    final previsao = alertas.firstWhere((a) => a.regra == RegraAlerta.limitePrevisto);
    final impacto = ImpactoSocial.calcular(
      alertas: alertas,
      decisoes: {
        previsao.id: RegistroDecisao(
          alertaId: previsao.id,
          decisao: Decisao.emAnalise,
          nota: '',
          quando: agora,
          tituloAlerta: previsao.titulo,
          indicador: previsao.indicador.nome,
        ),
      },
      relatos: 2,
      agora: agora,
    );
    expect(impacto.alertas, 2);
    expect(impacto.taxaDecisao, 0.5);
    expect(impacto.antecedenciaMedia, 2);
    expect(impacto.relatos, 2);
  });
}
