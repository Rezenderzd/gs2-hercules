import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/validacao.dart';
import '../rotas.dart';
import '../state/escopos.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/mensagens.dart';
import '../widgets/base.dart';
import '../widgets/campos.dart';

class EntrarScreen extends StatefulWidget {
  const EntrarScreen({super.key, this.destino});

  final String? destino;

  @override
  State<EntrarScreen> createState() => _EntrarScreenState();
}

class _EntrarScreenState extends State<EntrarScreen> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _entrando = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final preferencias = PreferenciasEscopo.de(context);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _entrando = true);
    try {
      await preferencias.entrar(_email.text);
      if (!mounted) return;
      _seguir();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _entrando = false);
      avisos.showSnackBar(SnackBar(content: Text(Mensagens.deFalha(erro, acao: 'salvar o e-mail'))));
    }
  }

  void _seguir() {
    if (widget.destino == Rotas.novoRelato) {
      context.pushReplacementNamed(Rotas.novoRelato);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Rotas.inicio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const BarraTopo(),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: Pagina(
            formulario: true,
            children: [
              const SizedBox(height: Espacos.enorme),
              Semantics(header: true, child: Text('Quem está usando?', style: estilos.headlineLarge)),
              const SizedBox(height: Espacos.pequeno),
              Text(
                'Informe seu e-mail para enviar relatos. Não pedimos senha nem confirmação. '
                'O e-mail não aparece para outras pessoas: os relatos são públicos, mas sem '
                'identificar quem escreveu.',
                style: estilos.bodyLarge?.copyWith(color: cores.suave),
              ),
              const SizedBox(height: Espacos.grande),
              CampoTexto(
                rotulo: 'E-mail',
                controlador: _email,
                dica: 'nome@exemplo.com',
                tipo: TextInputType.emailAddress,
                validar: Validacao.email,
              ),
              const SizedBox(height: Espacos.grande),
              FilledButton(
                onPressed: _entrando ? null : _entrar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.botao)),
                child: const Text('Entrar'),
              ),
              const SizedBox(height: Espacos.medio),
              Text(
                'Você pode sair da conta ou apagar seus dados a qualquer momento em Ajustes.',
                style: estilos.bodySmall?.copyWith(color: cores.suave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
