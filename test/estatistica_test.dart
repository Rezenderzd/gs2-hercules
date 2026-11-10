import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sao_paulo_atento/logic/estatistica.dart';

void main() {
  group('Amostra', () {
    test('média e desvio padrão amostral', () {
      final amostra = Amostra([2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]);
      expect(amostra.media, 5);
      expect(amostra.desvio, closeTo(2.138, 0.001));
    });

    test('escore da média divide pelo erro-padrão (desvio ÷ √n)', () {
      final base = Amostra([10.0, 12.0, 10.0, 12.0, 10.0, 12.0]);
      final recentes = Amostra([13.0, 13.0, 13.0]);
      final esperado = (13 - base.media) / (base.desvio / math.sqrt(3));
      expect(base.escoreDaMedia(recentes), closeTo(esperado, 1e-9));
    });

    test('escore negativo quando a média cai', () {
      final base = Amostra([10.0, 12.0, 10.0, 12.0, 10.0, 12.0]);
      expect(base.escoreDaMedia(Amostra([8.0, 8.0, 8.0])), isNegative);
    });

    test('escore é zero quando a base não varia', () {
      expect(Amostra([10.0, 10.0, 10.0]).escoreDaMedia(Amostra([50.0])), 0);
    });
  });

  group('Projecao', () {
    test('suavização exponencial pesa mais os dias recentes', () {
      expect(Projecao.de([10.0, 10.0, 10.0, 20.0], alfa: 0.5).proximoDia, 15);
    });

    test('MAPE é zero em série constante', () {
      expect(Projecao.de(List.filled(20, 8.0)).mape, closeTo(0, 1e-9));
    });

    test('MAPE é null com histórico curto', () {
      expect(Projecao.de([1.0, 2.0, 3.0]).mape, isNull);
    });
  });

  group('Tendencia', () {
    test('compara os últimos 7 dias com os 7 anteriores', () {
      final valores = [...List.filled(7, 100.0), ...List.filled(7, 120.0)];
      final tendencia = Tendencia.de(valores)!;
      expect(tendencia.variacao, closeTo(20, 1e-9));
      expect(tendencia.direcao, Direcao.subindo);
    });

    test('variação pequena é estável', () {
      final valores = [...List.filled(7, 100.0), ...List.filled(7, 102.0)];
      expect(Tendencia.de(valores)!.direcao, Direcao.estavel);
    });

    test('precisa de 14 dias', () {
      expect(Tendencia.de(List.filled(10, 1.0)), isNull);
    });
  });
}
