import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/indicador.dart';
import '../../models/relato.dart';
import '../../models/serie.dart';
import '../../rotas.dart';
import '../../state/escopos.dart';
import '../../theme/cores.dart';
import '../../widgets/base.dart';
import 'painel_base.dart';

class PainelLimpezaScreen extends StatelessWidget {
  const PainelLimpezaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PainelTema(
      tema: Tema.limpeza,
      tituloDestaque: 'Relatos dos cidadãos',
      destaque: _relatosPorCategoria,
    );
  }

  static List<Widget> _relatosPorCategoria(BuildContext context, List<Serie> series) {
    final estilos = Theme.of(context).textTheme;
    final cores = Cores.de(context);
    final contagem = RelatosEscopo.de(context).porCategoria();
    if (contagem.isEmpty) {
      return [
        Row(
          children: [
            Expanded(
              child: Text('Nenhum relato ainda.', style: estilos.bodyLarge?.copyWith(color: cores.suave)),
            ),
            TextButton(onPressed: () => context.pushNamed(Rotas.novoRelato), child: const Text('Relatar')),
          ],
        ),
      ];
    }
    final maior = contagem.values.fold<int>(0, (a, b) => b > a ? b : a);
    return [
      Cartao(
        child: Column(
          children: [
            for (final categoria in CategoriaRelato.values)
              if (contagem[categoria] case final total?)
                BarraSimples(rotulo: categoria.rotulo, valor: total.toDouble(), maximo: maior.toDouble()),
          ],
        ),
      ),
    ];
  }
}
