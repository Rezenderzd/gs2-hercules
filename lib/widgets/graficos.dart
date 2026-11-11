import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ponto.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';

class MiniLinha extends StatelessWidget {
  const MiniLinha({super.key, required this.valores, this.altura = 36});

  final List<double> valores;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: CustomPaint(painter: _PintorLinha(valores: valores, cor: Cores.de(context).destaque)),
      ),
    );
  }
}

class GraficoLinha extends StatelessWidget {
  const GraficoLinha({
    super.key,
    required this.pontos,
    required this.descricao,
    required this.unidade,
    this.referencias = const [],
    this.rotuloReferencia = 'limite',
    this.casas = 1,
    this.altura = 220,
  });

  final List<Ponto> pontos;
  final String descricao;
  final String unidade;
  final List<double> referencias;
  final String rotuloReferencia;
  final int casas;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final pequeno = Theme.of(context).textTheme.bodySmall?.copyWith(color: cores.suave);
    if (pontos.length < 2) {
      return SizedBox(height: altura, child: Center(child: Text('Dados insuficientes', style: pequeno)));
    }

    String fmt(double v) => Formato.numero(v, casas: casas);
    final valores = pontos.map((p) => p.valor);
    final observados = pontos.where((p) => !p.previsto).toList();
    final previstos = pontos.where((p) => p.previsto).toList();
    final resumo = StringBuffer(
      '$descricao: ${pontos.length} dias, entre ${fmt(valores.reduce(math.min))} e '
      '${fmt(valores.reduce(math.max))} $unidade.',
    );
    if (observados.isNotEmpty) resumo.write(' Último valor: ${fmt(observados.last.valor)} $unidade.');
    if (previstos.isNotEmpty) resumo.write(' Previsão até ${Formato.dia(previstos.last.dia)}.');
    if (referencias.isNotEmpty) {
      resumo.write(' Referência ($rotuloReferencia): ${referencias.map(fmt).join(' e ')} $unidade.');
    }

    return Semantics(
      container: true,
      label: resumo.toString(),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(unidade, style: pequeno),
          const SizedBox(height: Espacos.pequeno),
          SizedBox(
            height: altura,
            width: double.infinity,
            child: CustomPaint(
              painter: _PintorGrafico(
                pontos: pontos,
                referencias: referencias,
                casas: casas,
                cor: cores.destaque,
                corLimite: cores.critico,
                corGuia: cores.linha,
                corEixo: cores.suave,
                estiloRotulo: pequeno ?? const TextStyle(fontSize: 12),
                escalaTexto: MediaQuery.textScalerOf(context),
              ),
            ),
          ),
          if (previstos.isNotEmpty || referencias.isNotEmpty) ...[
            const SizedBox(height: Espacos.pequeno),
            Wrap(
              spacing: Espacos.medio,
              children: [
                if (previstos.isNotEmpty) Text('- - - previsão', style: pequeno),
                if (referencias.isNotEmpty)
                  Text(
                    '- - - $rotuloReferencia: ${referencias.map(fmt).join(' e ')} $unidade',
                    style: pequeno?.copyWith(color: cores.critico),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

void _tracejado(Canvas canvas, Offset de, Offset ate, Paint pincel) {
  final total = (ate - de).distance;
  if (total == 0) return;
  final direcao = (ate - de) / total;
  for (var andado = 0.0; andado < total; andado += 9) {
    canvas.drawLine(de + direcao * andado, de + direcao * math.min(andado + 5, total), pincel);
  }
}

class _PintorLinha extends CustomPainter {
  const _PintorLinha({required this.valores, required this.cor});

  final List<double> valores;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2) return;
    final minimo = valores.reduce(math.min);
    final faixa = math.max(valores.reduce(math.max) - minimo, 1e-9);
    final caminho = Path();
    for (var i = 0; i < valores.length; i++) {
      final x = size.width * i / (valores.length - 1);
      final y = size.height - (valores[i] - minimo) / faixa * (size.height - 4) - 2;
      if (i == 0) {
        caminho.moveTo(x, y);
      } else {
        caminho.lineTo(x, y);
      }
    }
    canvas.drawPath(
      caminho,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PintorLinha antigo) => antigo.valores != valores || antigo.cor != cor;
}

class _PintorGrafico extends CustomPainter {
  const _PintorGrafico({
    required this.pontos,
    required this.referencias,
    required this.casas,
    required this.cor,
    required this.corLimite,
    required this.corGuia,
    required this.corEixo,
    required this.estiloRotulo,
    required this.escalaTexto,
  });

  final List<Ponto> pontos;
  final List<double> referencias;
  final int casas;
  final Color cor;
  final Color corLimite;
  final Color corGuia;
  final Color corEixo;
  final TextStyle estiloRotulo;
  final TextScaler escalaTexto;

  static const int _marcasY = 4;

  TextPainter _rotulo(String texto) {
    return TextPainter(
      text: TextSpan(text: texto, style: estiloRotulo),
      textDirection: TextDirection.ltr,
      textScaler: escalaTexto,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final todos = [...pontos.map((p) => p.valor), ...referencias];
    var minimo = todos.reduce(math.min);
    var maximo = todos.reduce(math.max);
    final folga = math.max((maximo - minimo) * 0.1, 1.0);
    minimo = math.max(0, minimo - folga).toDouble();
    maximo += folga;

    final rotulosY = [
      for (var i = 0; i <= _marcasY; i++)
        _rotulo(Formato.numero(minimo + (maximo - minimo) * i / _marcasY, casas: casas)),
    ];
    final indicesX = {0, (pontos.length - 1) ~/ 2, pontos.length - 1}.toList()..sort();
    final rotulosX = [for (final i in indicesX) _rotulo(Formato.dia(pontos[i].dia))];

    final larguraY = rotulosY.map((r) => r.width).reduce(math.max);
    final alturaTexto = rotulosY.first.height;
    final area = Rect.fromLTRB(
      larguraY + 8,
      alturaTexto / 2,
      size.width - rotulosX.last.width / 2,
      size.height - alturaTexto - 6,
    );
    if (area.width <= 0 || area.height <= 0) return;

    double yDe(double v) => area.bottom - (v - minimo) / (maximo - minimo) * area.height;
    double xDe(int i) => area.left + area.width * i / (pontos.length - 1);
    Offset em(int i, double v) => Offset(xDe(i), yDe(v));

    final guia = Paint()
      ..color = corGuia
      ..strokeWidth = 1;
    for (var i = 0; i <= _marcasY; i++) {
      final y = area.bottom - area.height * i / _marcasY;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), guia);
      final r = rotulosY[i];
      r.paint(canvas, Offset(area.left - 8 - r.width, y - r.height / 2));
    }

    final eixo = Paint()
      ..color = corEixo
      ..strokeWidth = 1.2;
    canvas.drawLine(area.bottomLeft, area.topLeft, eixo);
    canvas.drawLine(area.bottomLeft, area.bottomRight, eixo);

    for (var k = 0; k < indicesX.length; k++) {
      final x = xDe(indicesX[k]);
      canvas.drawLine(Offset(x, area.bottom), Offset(x, area.bottom + 4), eixo);
      final r = rotulosX[k];
      final esquerda = math.min(math.max(0.0, x - r.width / 2), math.max(0.0, size.width - r.width));
      r.paint(canvas, Offset(esquerda, area.bottom + 6));
    }

    final pincelReferencia = Paint()
      ..color = corLimite
      ..strokeWidth = 1.2;
    for (final valor in referencias) {
      final y = yDe(valor);
      _tracejado(canvas, Offset(area.left, y), Offset(area.right, y), pincelReferencia);
    }

    final cheia = Paint()
      ..color = cor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final caminho = Path();
    var ultimoObservado = -1;
    for (var i = 0; i < pontos.length; i++) {
      if (pontos[i].previsto) continue;
      final o = em(i, pontos[i].valor);
      if (ultimoObservado < 0) {
        caminho.moveTo(o.dx, o.dy);
      } else {
        caminho.lineTo(o.dx, o.dy);
      }
      ultimoObservado = i;
    }
    canvas.drawPath(caminho, cheia);

    final tracejada = Paint()
      ..color = cor
      ..strokeWidth = 2;
    Offset? anterior = ultimoObservado >= 0 ? em(ultimoObservado, pontos[ultimoObservado].valor) : null;
    for (var i = 0; i < pontos.length; i++) {
      if (!pontos[i].previsto) continue;
      final atual = em(i, pontos[i].valor);
      if (anterior != null) _tracejado(canvas, anterior, atual, tracejada);
      anterior = atual;
    }

    if (ultimoObservado >= 0) {
      canvas.drawCircle(em(ultimoObservado, pontos[ultimoObservado].valor), 4, Paint()..color = cor);
    }
  }

  @override
  bool shouldRepaint(_PintorGrafico antigo) {
    return antigo.pontos != pontos ||
        antigo.referencias != referencias ||
        antigo.casas != casas ||
        antigo.cor != cor ||
        antigo.corLimite != corLimite ||
        antigo.corGuia != corGuia ||
        antigo.corEixo != corEixo ||
        antigo.estiloRotulo != estiloRotulo ||
        antigo.escalaTexto != escalaTexto;
  }
}
