import 'package:flutter/material.dart';

import '../../logic/estatistica.dart';
import '../../models/indicador.dart';
import '../../models/serie.dart';
import '../../widgets/base.dart';
import 'painel_base.dart';

class PainelMobilidadeScreen extends StatelessWidget {
  const PainelMobilidadeScreen({super.key});

  static const _nomesDias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  @override
  Widget build(BuildContext context) {
    return PainelTema(
      tema: Tema.mobilidade,
      tituloDestaque: 'Lotação média por dia da semana',
      destaque: _lotacaoPorDia,
    );
  }

  static List<Widget> _lotacaoPorDia(BuildContext context, List<Serie> series) {
    final lotacao = series.where((s) => s.indicador.id == Indicadores.lotacao.id).firstOrNull;
    if (lotacao == null) return const [];
    final porDia = <int, List<double>>{};
    for (final p in lotacao.observados) {
      porDia.putIfAbsent(p.dia.weekday, () => []).add(p.valor);
    }
    return [
      Cartao(
        child: Column(
          children: [
            for (var dia = DateTime.monday; dia <= DateTime.sunday; dia++)
              if (porDia[dia] case final valores?)
                BarraSimples(
                  rotulo: _nomesDias[dia - 1],
                  valor: Amostra(valores).media,
                  maximo: 100,
                  sufixo: '%',
                ),
          ],
        ),
      ),
    ];
  }
}
