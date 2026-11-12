import 'package:flutter/material.dart';

import '../logic/validacao.dart';
import '../models/limites.dart';
import '../state/escopos.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../widgets/base.dart';
import '../util/mensagens.dart';
import '../widgets/campos.dart';

class LimitesScreen extends StatefulWidget {
  const LimitesScreen({super.key});

  @override
  State<LimitesScreen> createState() => _LimitesScreenState();
}

class _LimitesScreenState extends State<LimitesScreen> {
  final _formulario = GlobalKey<FormState>();
  final _sensacao = TextEditingController();
  final _uv = TextEditingController();
  final _chuva = TextEditingController();
  final _escoreZ = TextEditingController();
  bool _preenchido = false;
  bool _salvando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preenchido) return;
    _preencher(PreferenciasEscopo.de(context).limites);
    _preenchido = true;
  }

  @override
  void dispose() {
    for (final c in [_sensacao, _uv, _chuva, _escoreZ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _preencher(Limites l) {
    _sensacao.text = Formato.compacto(l.sensacaoC);
    _uv.text = Formato.compacto(l.uv);
    _chuva.text = Formato.compacto(l.chuvaMm);
    _escoreZ.text = Formato.compacto(l.escoreZ);
  }

  Future<void> _salvar() async {
    if (!(_formulario.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confira os valores indicados.')));
      return;
    }
    await _gravar(
      Limites(
        sensacaoC: Validacao.lerNumero(_sensacao.text)!,
        uv: Validacao.lerNumero(_uv.text)!,
        chuvaMm: Validacao.lerNumero(_chuva.text)!,
        escoreZ: Validacao.lerNumero(_escoreZ.text)!,
      ),
      'Limites salvos para todos. Alertas recalculados.',
    );
  }

  Future<void> _restaurar() async {
    _preencher(Limites.padrao);
    await _gravar(Limites.padrao, 'Valores padrão restaurados.');
  }

  Future<void> _gravar(Limites limites, String sucesso) async {
    final territorio = TerritorioEscopo.de(context);
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _salvando = true);
    try {
      await territorio.salvarLimites(limites);
      avisos.showSnackBar(SnackBar(content: Text(sucesso)));
    } catch (erro) {
      avisos.showSnackBar(SnackBar(content: Text(Mensagens.deFalha(erro, acao: 'mudar os limites'))));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final podeMudar = TerritorioEscopo.de(context).podeMudarLimites;
    const vao = SizedBox(height: Espacos.grande);

    return Scaffold(
      appBar: const BarraTopo(title: Text('Limites dos alertas')),
      body: Form(
        key: _formulario,
        child: Pagina(
          formulario: true,
          children: [
            Text(
              podeMudar
                  ? 'A partir destes valores o app gera alertas. Ao salvar, os alertas de '
                      'todos os aparelhos passam a usar os novos valores.'
                  : 'A partir destes valores o app gera alertas. Eles valem para todos e só '
                      'gestores (com PIN, em Ajustes) podem alterá-los.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cores.suave),
            ),
            vao,
            CampoTexto(
              rotulo: 'Sensação térmica máxima',
              controlador: _sensacao,
              sufixo: '°C',
              numerico: true,
              habilitado: podeMudar,
              validar: (v) => Validacao.numeroNaFaixa(v, Limites.faixaSensacao, 'a sensação térmica'),
            ),
            vao,
            CampoTexto(
              rotulo: 'Índice UV máximo',
              controlador: _uv,
              numerico: true,
              habilitado: podeMudar,
              validar: (v) => Validacao.numeroNaFaixa(v, Limites.faixaUv, 'o índice UV'),
            ),
            vao,
            CampoTexto(
              rotulo: 'Chuva em um dia',
              controlador: _chuva,
              sufixo: 'mm',
              numerico: true,
              habilitado: podeMudar,
              validar: (v) => Validacao.numeroNaFaixa(v, Limites.faixaChuva, 'a chuva'),
            ),
            vao,
            CampoTexto(
              rotulo: 'Sensibilidade a anomalias (escore z)',
              controlador: _escoreZ,
              ajuda: 'Mobilidade e limpeza. Menor valor = mais alertas.',
              numerico: true,
              habilitado: podeMudar,
              validar: (v) => Validacao.numeroNaFaixa(v, Limites.faixaEscoreZ, 'o escore z'),
            ),
            const SizedBox(height: Espacos.enorme),
            if (podeMudar) ...[
              FilledButton(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.botao)),
                child: const Text('Salvar'),
              ),
              TextButton(
                onPressed: _salvando ? null : _restaurar,
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Espacos.toque)),
                child: const Text('Voltar aos valores padrão'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
