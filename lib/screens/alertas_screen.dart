import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/decisao.dart';
import '../rotas.dart';
import '../state/escopos.dart';
import '../state/status_carga.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../widgets/base.dart';
import '../widgets/estados.dart';

const _abas = [
  (Decisao.aguardando, 'Aguardando'),
  (Decisao.emAnalise, 'Em análise'),
  (Decisao.aprovada, 'Aprovados'),
  (Decisao.recusada, 'Recusados'),
];

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  Decisao _aba = Decisao.aguardando;

  @override
  Widget build(BuildContext context) {
    final territorio = TerritorioEscopo.de(context);
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;

    if (!territorio.temDados) {
      return Scaffold(
        appBar: const BarraTopo(title: Text('Alertas')),
        body: Centralizado(
          child: territorio.status == StatusCarga.erro
              ? EstadoTela.erro(texto: territorio.erro ?? '', aoTentar: territorio.carregar)
              : const EstadoTela.carregando(titulo: 'Calculando alertas...'),
        ),
      );
    }

    int contar(Decisao d) => territorio.alertas.where((a) => territorio.decisaoDe(a.id) == d).length;
    final alertas = territorio.alertas.where((a) => territorio.decisaoDe(a.id) == _aba).toList();

    return Scaffold(
      appBar: const BarraTopo(title: Text('Alertas')),
      body: Pagina(
        aoAtualizar: territorio.carregar,
        children: [
          if (territorio.avisoAtualizacao != null) AvisoFaixa(territorio.avisoAtualizacao!),
          Wrap(
            spacing: Espacos.pequeno,
            runSpacing: Espacos.pequeno,
            children: [
              for (final (decisao, rotulo) in _abas)
                ChoiceChip(
                  label: Text('$rotulo (${contar(decisao)})'),
                  selected: _aba == decisao,
                  onSelected: (_) => setState(() => _aba = decisao),
                ),
            ],
          ),
          const NotaDecisaoHumana(),
          if (alertas.isEmpty)
            EstadoTela.vazio(
              icone: Icons.check_circle_outline,
              titulo: _aba == Decisao.aguardando ? 'Nada aguardando decisão' : 'Nenhum alerta nesta aba',
              texto: _aba == Decisao.aguardando
                  ? 'Veja as outras abas para consultar o que já foi avaliado.'
                  : 'Quando um gestor decidir um alerta, ele aparece aqui.',
            )
          else
            Cartao(
              preenchimento: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < alertas.length; i++) ...[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: Espacos.margem, vertical: Espacos.minimo),
                      leading: Marcador(corDaGravidade(cores, alertas[i].gravidade)),
                      title: Text(alertas[i].titulo),
                      subtitle: Text(
                        _subtitulo(territorio.registroDe(alertas[i].id), alertas[i].indicador.tema.titulo),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(Rotas.alerta, pathParameters: {'id': alertas[i].id}),
                    ),
                    if (i < alertas.length - 1) const Divider(indent: Espacos.margem),
                  ],
                ],
              ),
            ),
          if (territorio.avisoDecisoes != null) ...[
            const SizedBox(height: Espacos.medio),
            Text(territorio.avisoDecisoes!, style: estilos.bodySmall?.copyWith(color: cores.atencao)),
          ],
        ],
      ),
    );
  }

  static String _subtitulo(RegistroDecisao? registro, String tema) {
    if (registro == null) return tema;
    final autor = registro.minha ? 'por você' : 'por um gestor';
    final envio = registro.pendente ? ' · aguardando envio' : '';
    return '$tema · ${registro.decisao.rotulo} $autor em ${Formato.dia(registro.quando)}$envio';
  }
}
