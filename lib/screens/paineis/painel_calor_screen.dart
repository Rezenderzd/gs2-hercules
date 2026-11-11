import 'package:flutter/material.dart';

import '../../models/indicador.dart';
import '../../models/serie.dart';
import '../../theme/cores.dart';
import '../../theme/espacos.dart';
import '../../util/formato.dart';
import '../../widgets/base.dart';
import 'painel_base.dart';

class PainelCalorScreen extends StatelessWidget {
  const PainelCalorScreen({super.key});

  static const double _larguraDia = 56;

  @override
  Widget build(BuildContext context) {
    return PainelTema(tema: Tema.calor, tituloDestaque: 'Próximos dias', destaque: _proximosDias);
  }

  static List<Widget> _proximosDias(BuildContext context, List<Serie> series) {
    final estilos = Theme.of(context).textTheme;
    final cores = Cores.de(context);
    Serie? serie(Indicador i) => series.where((s) => s.indicador.id == i.id).firstOrNull;
    final sensacao = serie(Indicadores.sensacao);
    final uv = serie(Indicadores.uv);
    final chuva = serie(Indicadores.chuva);
    if (sensacao == null || sensacao.previstos.isEmpty) return const [];

    String valor(Serie? s, DateTime dia, String sufixo) {
      final p = s?.previstos.where((x) => x.dia == dia).firstOrNull;
      return p == null ? '—' : '${Formato.numero(p.valor, casas: 0)}$sufixo';
    }

    return [
      Cartao(
        preenchimento: const EdgeInsets.symmetric(horizontal: Espacos.margem, vertical: Espacos.pequeno),
        child: Column(
          children: [
            for (final p in sensacao.previstos)
              Semantics(
                label: '${Formato.diaSemana(p.dia)}: sensação ${valor(sensacao, p.dia, ' graus')}, '
                    'UV ${valor(uv, p.dia, '')}, chuva ${valor(chuva, p.dia, ' milímetros')}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Espacos.entre),
                  child: Row(
                    children: [
                      SizedBox(
                        width: _larguraDia,
                        child: Text(Formato.diaSemanaCurto(p.dia), style: estilos.bodyLarge),
                      ),
                      Expanded(child: Text(valor(sensacao, p.dia, '°'), style: estilos.titleMedium)),
                      Expanded(child: Text('UV ${valor(uv, p.dia, '')}', style: estilos.bodyMedium)),
                      Text(valor(chuva, p.dia, ' mm'), style: estilos.bodyMedium?.copyWith(color: cores.suave)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}
