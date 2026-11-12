import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/territorio.dart';
import '../logic/validacao.dart';
import '../models/relato.dart';
import '../rotas.dart';
import '../state/escopos.dart';
import '../theme/espacos.dart';
import '../util/datas.dart';
import '../util/formato.dart';
import '../widgets/base.dart';
import '../util/mensagens.dart';
import '../widgets/campos.dart';

class NovoRelatoScreen extends StatefulWidget {
  const NovoRelatoScreen({super.key});

  @override
  State<NovoRelatoScreen> createState() => _NovoRelatoScreenState();
}

class _NovoRelatoScreenState extends State<NovoRelatoScreen> {
  final _formulario = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  CategoriaRelato? _categoria;
  String? _bairro;
  Urgencia? _urgencia;
  DateTime? _dia;
  bool _enviando = false;

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<DateTime?> _escolherDia(BuildContext context, DateTime? atual) {
    final hoje = Datas.soDia(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: atual ?? hoje,
      firstDate: Datas.somarDias(hoje, -Validacao.diasRetroativos),
      lastDate: hoje,
      helpText: 'Quando você viu?',
    );
  }

  Future<void> _enviar() async {
    final relatos = RelatosEscopo.de(context);
    final avisos = ScaffoldMessenger.of(context);
    final formulario = _formulario.currentState;
    if (formulario == null) return;
    if (!formulario.validate()) {
      avisos.showSnackBar(const SnackBar(content: Text('Confira os campos indicados.')));
      return;
    }
    formulario.save();

    setState(() => _enviando = true);
    try {
      final salvo = await relatos.registrar(
        RascunhoRelato(
          categoria: _categoria!,
          bairro: _bairro!,
          descricao: _descricao.text,
          urgencia: _urgencia!,
          observadoEm: _dia!,
        ),
      );
      avisos.showSnackBar(
        SnackBar(
          content: Text(
            salvo
                ? 'Relato enviado. Obrigado!'
                : 'Relato guardado neste aparelho. Ele será enviado quando a conexão voltar.',
          ),
        ),
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(Rotas.relatos);
      }
    } catch (erro) {
      if (!mounted) return;
      setState(() => _enviando = false);
      avisos.showSnackBar(SnackBar(content: Text(Mensagens.deFalha(erro, acao: 'enviar o relato'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    const vao = SizedBox(height: Espacos.grande);

    return Scaffold(
      appBar: const BarraTopo(title: Text('Novo relato')),
      body: Form(
        key: _formulario,
        child: Pagina(
          formulario: true,
          children: [
            const SizedBox(height: Espacos.pequeno),
            CampoEscolha<CategoriaRelato>(
              rotulo: 'O que aconteceu?',
              opcoes: CategoriaRelato.values,
              textoDe: (c) => c.rotulo,
              validator: (v) => Validacao.escolha(v, 'Escolha o tipo de problema.'),
              onSaved: (v) => _categoria = v,
            ),
            vao,
            CampoEscolha<String>(
              rotulo: 'Onde?',
              opcoes: Territorio.bairros,
              textoDe: (b) => b,
              validator: (v) => Validacao.escolha(v, 'Escolha o bairro.'),
              onSaved: (v) => _bairro = v,
            ),
            vao,
            CampoData(
              rotulo: 'Quando?',
              initialValue: Datas.soDia(DateTime.now()),
              textoDe: (d) => '${Formato.diaSemana(d)}, ${Formato.data(d)}',
              escolher: _escolherDia,
              validator: (v) => Validacao.dataObservacao(v, DateTime.now()),
              onSaved: (v) => _dia = v,
            ),
            vao,
            CampoEscolha<Urgencia>(
              rotulo: 'Urgência',
              opcoes: Urgencia.values,
              textoDe: (u) => u.rotulo,
              validator: (v) => Validacao.escolha(v, 'Diga o quanto é urgente.'),
              onSaved: (v) => _urgencia = v,
            ),
            vao,
            CampoTexto(
              rotulo: 'Descreva',
              controlador: _descricao,
              dica: 'Ex.: lixo acumulado na esquina da praça há três dias.',
              ajuda: '${Validacao.descricaoMinima} a ${Validacao.descricaoMaxima} caracteres, sem dados pessoais.',
              linhas: 4,
              maximo: Validacao.descricaoMaxima,
              validar: Validacao.descricao,
            ),
            const SizedBox(height: Espacos.pequeno),
            CampoAceite(
              texto: 'Não escrevi nome, telefone, e-mail ou documento de ninguém.',
              validator: (v) => Validacao.aceite(v, 'Confirme que o relato não tem dados pessoais.'),
            ),
            const SizedBox(height: Espacos.medio),
            Text(
              'O relato fica visível para todos, sem o seu e-mail. Ele é ligado à sua conta '
              '(${PreferenciasEscopo.de(context).email ?? ''}) só para você poder apagá-lo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Espacos.medio),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.botao)),
              child: _enviando
                  ? const SizedBox(
                      width: Espacos.progressoBotao,
                      height: Espacos.progressoBotao,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar relato'),
            ),
          ],
        ),
      ),
    );
  }
}
