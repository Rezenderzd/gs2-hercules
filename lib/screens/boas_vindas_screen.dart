import 'package:flutter/material.dart';

import '../logic/validacao.dart';
import '../state/escopos.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../widgets/base.dart';
import '../util/mensagens.dart';
import '../widgets/campos.dart';

class BoasVindasScreen extends StatefulWidget {
  const BoasVindasScreen({super.key});

  @override
  State<BoasVindasScreen> createState() => _BoasVindasScreenState();
}

class _BoasVindasScreenState extends State<BoasVindasScreen> {
  final _formulario = GlobalKey<FormState>();
  bool _salvando = false;

  Future<void> _aceitar() async {
    final preferencias = PreferenciasEscopo.de(context);
    final avisos = ScaffoldMessenger.of(context);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);
    try {
      await preferencias.aceitar();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      avisos.showSnackBar(SnackBar(content: Text(Mensagens.deFalha(erro, acao: 'salvar o aceite'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;

    Widget linha(IconData icone, String texto) => Padding(
          padding: const EdgeInsets.only(bottom: Espacos.medio),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icone, color: cores.destaque)),
              const SizedBox(width: Espacos.medio),
              Expanded(child: Text(texto, style: estilos.bodyLarge)),
            ],
          ),
        );

    return Scaffold(
      appBar: const BarraTopo(),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: Pagina(
            formulario: true,
            children: [
              const SizedBox(height: Espacos.enorme),
              Semantics(header: true, child: Text('São Paulo Atento', style: estilos.headlineLarge)),
              const SizedBox(height: Espacos.pequeno),
              Text(
                'O que pede atenção no Centro de São Paulo, antes de virar problema.',
                style: estilos.titleMedium?.copyWith(color: cores.suave, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: Espacos.enorme),
              linha(Icons.insights, 'Calor, mobilidade e limpeza urbana em um só lugar.'),
              linha(Icons.person_outline, 'Os alertas explicam seus números. Quem decide é sempre um gestor.'),
              linha(Icons.visibility_outlined,
                  'Painéis e alertas abrem sem cadastro. Para enviar relatos, pedimos só o seu e-mail '
                  '(sem senha e sem confirmação).'),
              linha(Icons.cloud_outlined,
                  'Onde ficam os dados: relatos e decisões são guardados no Supabase, um serviço de '
                  'banco de dados na nuvem mantido por terceiros, e copiados neste aparelho para '
                  'uso sem internet.'),
              linha(Icons.lock_outline,
                  'Quem vê o quê: categoria, bairro, data e texto dos relatos ficam visíveis para '
                  'todos os usuários, sem o seu e-mail. O e-mail fica numa área restrita, vista só '
                  'pelos responsáveis pelo projeto. Nada de nome, telefone, CPF ou GPS.'),
              linha(Icons.delete_outline,
                  'Você pode sair da conta ou apagar seus relatos e o e-mail em Ajustes, a qualquer '
                  'momento.'),
              const SizedBox(height: Espacos.grande),
              CampoAceite(
                texto: 'Li e concordo com o uso dos dados descrito acima.',
                validator: (v) => Validacao.aceite(v, 'Precisamos do seu aceite para continuar.'),
              ),
              CampoAceite(
                texto: 'Entendo que os alertas não substituem a decisão humana.',
                validator: (v) => Validacao.aceite(v, 'Confirme que entendeu o papel dos alertas.'),
              ),
              const SizedBox(height: Espacos.grande),
              FilledButton(
                onPressed: _salvando ? null : _aceitar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.botao)),
                child: _salvando
                    ? const SizedBox(
                        width: Espacos.progressoBotao,
                        height: Espacos.progressoBotao,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Começar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
