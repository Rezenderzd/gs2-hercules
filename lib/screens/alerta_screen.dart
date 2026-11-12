import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/alerta.dart';
import '../models/decisao.dart';
import '../rotas.dart';
import '../state/escopos.dart';
import '../state/territorio_store.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../util/mensagens.dart';
import '../widgets/base.dart';
import '../widgets/campos.dart';
import '../widgets/estados.dart';

class AlertaScreen extends StatefulWidget {
  const AlertaScreen({super.key, required this.alertaId});

  final String alertaId;

  @override
  State<AlertaScreen> createState() => _AlertaScreenState();
}

class _AlertaScreenState extends State<AlertaScreen> {
  final _nota = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _decidir(Alerta alerta, Decisao decisao) async {
    final territorio = TerritorioEscopo.de(context);
    final avisos = ScaffoldMessenger.of(context);

    if (decisao == Decisao.aprovada) {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: const Text('Aprovar a sugestão?'),
          content: const Text(
            'Você leu as evidências e os limites deste alerta? O app só registra '
            'a decisão; a ação é executada pela equipe responsável.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogo).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(dialogo).pop(true), child: const Text('Aprovar')),
          ],
        ),
      );
      if (confirmou != true || !mounted) return;
    }

    setState(() => _salvando = true);
    try {
      final enviada = await territorio.decidir(alerta, decisao, nota: _nota.text);
      if (mounted) _nota.clear();
      avisos.showSnackBar(
        SnackBar(
          content: Text(
            enviada
                ? 'Decisão registrada: ${decisao.rotulo}.'
                : 'Decisão guardada neste aparelho; será enviada quando a conexão voltar.',
          ),
        ),
      );
    } catch (erro) {
      avisos.showSnackBar(SnackBar(content: Text(Mensagens.deFalha(erro, acao: 'registrar a decisão'))));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final territorio = TerritorioEscopo.de(context);
    final alerta = territorio.alerta(widget.alertaId);

    if (alerta == null) {
      return Scaffold(
        appBar: const BarraTopo(),
        body: Centralizado(
          child: territorio.carregando
              ? const EstadoTela.carregando()
              : EstadoTela.vazio(
                  icone: Icons.notifications_off_outlined,
                  titulo: 'Este alerta não está mais ativo',
                  texto: 'Os dados foram atualizados ou os limites mudaram.',
                  rotuloAcao: 'Ver alertas',
                  acao: () => context.goNamed(Rotas.alertas),
                ),
        ),
      );
    }

    return Scaffold(
      appBar: const BarraTopo(),
      body: Pagina(formulario: true, children: _conteudo(context, territorio, alerta)),
    );
  }

  List<Widget> _conteudo(BuildContext context, TerritorioStore territorio, Alerta alerta) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    final registro = territorio.registroDe(alerta.id);

    Widget lista(List<String> itens) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in itens)
              Padding(
                padding: const EdgeInsets.only(bottom: Espacos.pequeno),
                child: Text('• $item', style: estilos.bodyLarge),
              ),
          ],
        );

    final nivel = alerta.nivelQualidade.rotulo;
    return [
      Row(
        children: [
          Marcador(corDaGravidade(cores, alerta.gravidade)),
          const SizedBox(width: Espacos.pequeno),
          Expanded(
            child: Text(
              '${alerta.gravidade.rotulo} · ${alerta.indicador.tema.titulo}',
              style: estilos.bodyMedium?.copyWith(color: cores.suave),
            ),
          ),
        ],
      ),
      const SizedBox(height: Espacos.pequeno),
      Semantics(header: true, child: Text(alerta.titulo, style: estilos.headlineSmall)),
      const SizedBox(height: Espacos.medio),
      Text(alerta.resumo, style: estilos.bodyLarge),
      const TituloSecao('Por que este alerta'),
      lista(alerta.evidencias),
      const TituloSecao('Qualidade da evidência'),
      Text(
        '${nivel[0].toUpperCase()}${nivel.substring(1)} · nota ${alerta.notaQualidade} de 100',
        style: estilos.titleLarge,
      ),
      const SizedBox(height: Espacos.minimo),
      Text(
        'Não é a probabilidade de o problema acontecer: resume o quanto os dados e o sinal '
        'são bons.',
        style: estilos.bodySmall?.copyWith(color: cores.suave),
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Como foi calculada', style: estilos.bodyMedium?.copyWith(color: cores.destaque)),
        shape: const Border(),
        collapsedShape: const Border(),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Média dos fatores da regra × peso da fonte dos dados, entre 5 e 95.',
            style: estilos.bodySmall?.copyWith(color: cores.suave),
          ),
          const SizedBox(height: Espacos.pequeno),
          for (final fator in alerta.fatores.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.minimo),
              child: Row(
                children: [
                  Expanded(child: Text(fator.key)),
                  Text('${(fator.value * 100).round()} de 100'),
                ],
              ),
            ),
        ],
      ),
      const TituloSecao('Limites desta análise'),
      lista(alerta.limitacoes),
      const TituloSecao('Sugestão para a equipe'),
      Text(alerta.sugestao, style: estilos.bodyLarge),
      const NotaDecisaoHumana(),
      const TituloSecao('Decisão'),
      Text(_situacao(registro), style: estilos.bodyLarge),
      if (territorio.avisoDecisoes != null)
        Padding(
          padding: const EdgeInsets.only(top: Espacos.pequeno),
          child: Text(territorio.avisoDecisoes!, style: estilos.bodySmall?.copyWith(color: cores.atencao)),
        ),
      const SizedBox(height: Espacos.medio),
      if (territorio.podeDecidir)
        ..._botoesDeDecisao(alerta, territorio.decisaoDe(alerta.id))
      else
        _QuemDecide(entrou: PreferenciasEscopo.de(context).entrou),
      TextButton(
        onPressed: () => context.pushNamed(Rotas.indicador, pathParameters: {'id': alerta.indicador.id}),
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.toque)),
        child: Text('Ver o indicador: ${alerta.indicador.nome}'),
      ),
    ];
  }

  static String _situacao(RegistroDecisao? registro) {
    if (registro == null) return 'Ainda não avaliado.';
    final autor = registro.minha ? 'por você' : 'por um gestor';
    final nota = registro.nota.isEmpty ? '' : ' — "${registro.nota}"';
    final envio = registro.pendente ? ' (aguardando envio)' : '';
    return '${registro.decisao.rotulo} $autor em ${Formato.dataHora(registro.quando)}$nota$envio';
  }

  List<Widget> _botoesDeDecisao(Alerta alerta, Decisao atual) {
    return [
      CampoTexto(
        rotulo: 'Observação (opcional)',
        controlador: _nota,
        ajuda: 'Não escreva dados pessoais; eles são removidos.',
        maximo: 200,
      ),
      const SizedBox(height: Espacos.medio),
      FilledButton(
        onPressed: _salvando || atual == Decisao.aprovada ? null : () => _decidir(alerta, Decisao.aprovada),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.toque)),
        child: const Text('Aprovar sugestão'),
      ),
      const SizedBox(height: Espacos.pequeno),
      OutlinedButton(
        onPressed: _salvando || atual == Decisao.emAnalise ? null : () => _decidir(alerta, Decisao.emAnalise),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.toque)),
        child: const Text('Colocar em análise'),
      ),
      TextButton(
        onPressed: _salvando || atual == Decisao.recusada ? null : () => _decidir(alerta, Decisao.recusada),
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.toque)),
        child: const Text('Recusar sugestão'),
      ),
    ];
  }
}

class _QuemDecide extends StatelessWidget {
  const _QuemDecide({required this.entrou});

  final bool entrou;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Só gestores cadastrados aprovam ou recusam alertas. Se você é gestor, '
            '${entrou ? 'informe o seu PIN em Ajustes → Área do gestor.' : 'entre com o seu e-mail e depois informe o PIN em Ajustes.'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cores.suave),
          ),
          const SizedBox(height: Espacos.pequeno),
          TextButton(
            onPressed: () {
              if (entrou) {
                context.goNamed(Rotas.ajustes);
              } else {
                context.pushNamed(Rotas.entrar);
              }
            },
            style: TextButton.styleFrom(minimumSize: const Size(Espacos.toque, Espacos.toque)),
            child: Text(entrou ? 'Ir para Ajustes' : 'Entrar com e-mail'),
          ),
        ],
      ),
    );
  }
}
