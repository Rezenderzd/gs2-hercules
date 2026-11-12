import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../rotas.dart';
import '../services/nuvem/servico_nuvem.dart';
import '../state/escopos.dart';
import '../state/preferencias_store.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../util/mensagens.dart';
import '../widgets/base.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  static const _semTitularidade =
      'Por segurança, os dados de um e-mail só podem ser apagados no aparelho em que ele '
      'foi usado pela primeira vez. Use aquele aparelho ou peça a exclusão aos '
      'responsáveis pelo projeto (contato no README).';

  Future<void> _apagarDados(BuildContext context) async {
    final preferencias = PreferenciasEscopo.de(context);
    final territorio = TerritorioEscopo.de(context);
    final relatos = RelatosEscopo.de(context);
    final avisos = ScaffoldMessenger.of(context);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: Text(
          preferencias.entrou
              ? 'Seus relatos e o registro do e-mail ${preferencias.email} serão apagados '
                  '(na nuvem e neste aparelho) e o aceite será revogado. Decisões tomadas como '
                  'gestor continuam no histórico, sem o seu nome. Não dá para desfazer.'
              : 'O aceite de privacidade será revogado e o app voltará à tela inicial.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogo).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogo).pop(true), child: const Text('Apagar')),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      if (preferencias.entrou) {
        await relatos.apagarMeusDados();
        await territorio.recarregarDecisoes();
      }
      await preferencias.revogar();
    } on FalhaNuvem catch (falha) {
      avisos.showSnackBar(
        SnackBar(
          content: Text(
            falha.tipo == TipoFalhaNuvem.naoAutorizado
                ? _semTitularidade
                : Mensagens.deFalha(falha, acao: 'apagar os dados'),
          ),
        ),
      );
    } catch (erro) {
      avisos.showSnackBar(SnackBar(content: Text(Mensagens.deFalha(erro, acao: 'apagar os dados'))));
    }
  }

  Future<void> _sair(BuildContext context) async {
    final preferencias = PreferenciasEscopo.de(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Os painéis continuam abertos. Para relatar ou decidir alertas, será preciso '
          'informar um e-mail de novo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogo).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogo).pop(true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirmou == true) await preferencias.sair();
  }

  Future<void> _entrarComoGestor(BuildContext context) async {
    final preferencias = PreferenciasEscopo.de(context);
    final avisos = ScaffoldMessenger.of(context);
    final pin = await showDialog<String>(context: context, builder: (_) => const _DialogoPin());
    if (pin == null || pin.isEmpty) return;
    try {
      final valido = await preferencias.entrarComoGestor(pin);
      avisos.showSnackBar(
        SnackBar(
          content: Text(
            valido
                ? 'PIN confirmado. Você pode decidir alertas e mudar os limites.'
                : 'PIN incorreto ou e-mail não cadastrado como gestor.',
          ),
        ),
      );
    } catch (erro) {
      avisos.showSnackBar(SnackBar(content: Text(Mensagens.deFalha(erro, acao: 'conferir o PIN'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencias = PreferenciasEscopo.de(context);
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const BarraTopo(title: Text('Ajustes')),
      body: Pagina(
        children: [
          const TituloSecao('Aparência'),
          Cartao(
            preenchimento: const EdgeInsets.symmetric(horizontal: Espacos.margem, vertical: Espacos.pequeno),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo claro ou escuro: toque no ícone de sol/lua no topo de qualquer tela.',
                  style: estilos.bodyMedium?.copyWith(color: cores.suave),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alto contraste'),
                  subtitle: const Text('Cores mais fortes e bordas escuras'),
                  value: preferencias.altoContraste,
                  onChanged: preferencias.definirAltoContraste,
                ),
                Text('Tamanho do texto · ${Formato.porcento(preferencias.escalaFonte)}'),
                Slider(
                  value: preferencias.escalaFonte,
                  min: PreferenciasStore.fonteMinima,
                  max: PreferenciasStore.fonteMaxima,
                  divisions: 5,
                  label: Formato.porcento(preferencias.escalaFonte),
                  semanticFormatterCallback: (v) => 'Texto em ${Formato.porcento(v)}',
                  onChanged: preferencias.definirEscalaFonte,
                ),
              ],
            ),
          ),
          const TituloSecao('Alertas e dados'),
          Cartao(
            preenchimento: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Limites dos alertas'),
                  subtitle: Text(
                    preferencias.usaNuvem
                        ? 'Iguais para todos; só gestores alteram'
                        : 'Quando um valor vira alerta',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(Rotas.limites),
                ),
                const Divider(indent: Espacos.medio),
                ListTile(
                  title: const Text('Como funcionam os números'),
                  subtitle: const Text('Fontes, métricas, limites e impacto'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(Rotas.sobre),
                ),
              ],
            ),
          ),
          const TituloSecao('Conta'),
          if (preferencias.entrou) _conta(context, preferencias) else _semConta(context),
          const SizedBox(height: Espacos.grande),
          if (preferencias.aceiteEm != null)
            Text(
              'Aceite de privacidade em ${Formato.data(preferencias.aceiteEm!)}.',
              style: estilos.bodySmall?.copyWith(color: cores.suave),
            ),
          const SizedBox(height: Espacos.minimo),
          Text(
            'São Paulo Atento 1.0 · FIAP · Global Solution 2026.2',
            style: estilos.bodySmall?.copyWith(color: cores.suave),
          ),
        ],
      ),
    );
  }

  Widget _semConta(BuildContext context) {
    final cores = Cores.de(context);
    return Cartao(
      preenchimento: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Entrar com e-mail'),
            subtitle: const Text('Necessário para relatar e para gestores decidirem alertas'),
            onTap: () => context.pushNamed(Rotas.entrar),
          ),
          const Divider(indent: Espacos.medio),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: cores.critico),
            title: Text('Revogar o aceite', style: TextStyle(color: cores.critico)),
            onTap: () => _apagarDados(context),
          ),
        ],
      ),
    );
  }

  Widget _conta(BuildContext context, PreferenciasStore preferencias) {
    final cores = Cores.de(context);
    final nuvem = preferencias.usaNuvem;
    final titularidade = switch (preferencias.titular) {
      _ when !nuvem => 'Dados salvos só neste aparelho',
      true => 'Dados na nuvem (Supabase) · este aparelho pode apagá-los',
      false => 'Dados na nuvem (Supabase) · e-mail registrado em outro aparelho',
      null => 'Dados na nuvem (Supabase) · aguardando conexão para confirmar a conta',
    };
    return Cartao(
      preenchimento: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(preferencias.email ?? '—'),
            subtitle: Text(titularidade),
          ),
          const Divider(indent: Espacos.medio),
          if (preferencias.gestor)
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Você é gestor'),
              subtitle: const Text('Pode decidir alertas e mudar limites. Toque para sair do modo gestor.'),
              onTap: preferencias.sairDoGestor,
            )
          else
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Área do gestor'),
              subtitle: Text(
                preferencias.gestorCadastrado
                    ? 'Seu e-mail é de gestor: informe o PIN'
                    : 'Para quem foi cadastrado como gestor',
              ),
              onTap: () => _entrarComoGestor(context),
            ),
          const Divider(indent: Espacos.medio),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair da conta'),
            onTap: () => _sair(context),
          ),
          const Divider(indent: Espacos.medio),
          ListTile(
            leading: Icon(Icons.delete_outline, color: cores.critico),
            title: Text('Apagar meus dados', style: TextStyle(color: cores.critico)),
            subtitle: Text(
              preferencias.titular == false && nuvem
                  ? 'Só no aparelho em que o e-mail foi usado primeiro'
                  : 'Apaga seus relatos e o e-mail e revoga o aceite',
            ),
            onTap: () => _apagarDados(context),
          ),
        ],
      ),
    );
  }
}

class _DialogoPin extends StatefulWidget {
  const _DialogoPin();

  @override
  State<_DialogoPin> createState() => _DialogoPinState();
}

class _DialogoPinState extends State<_DialogoPin> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN do gestor'),
      content: TextField(
        controller: _pin,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 12,
        decoration: const InputDecoration(labelText: 'PIN', helperText: 'Recebido de quem administra o projeto'),
        onSubmitted: (valor) => Navigator.of(context).pop(valor.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_pin.text.trim()), child: const Text('Confirmar')),
      ],
    );
  }
}
