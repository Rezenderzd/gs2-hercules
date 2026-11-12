import 'package:flutter/material.dart';

import '../logic/regras/regra_anomalia.dart';
import '../logic/regras/regra_previsao.dart';
import '../state/escopos.dart';
import '../theme/cores.dart';
import '../theme/espacos.dart';
import '../util/formato.dart';
import '../widgets/base.dart';

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  static final _secoes = <(String, List<String>)>[
    ('De onde vêm os dados', [
      'Clima (real): API pública Open-Meteo — sensação térmica, índice UV e chuva, '
          'com 30 dias de histórico e 7 de previsão. Sem chave de acesso (CC BY 4.0).',
      'Mobilidade e limpeza (simulados): não há API aberta diária desses dados para '
          'o Centro; um simulador gera séries com padrão semanal e ruído.',
      'Relatos e decisões: guardados no Supabase (banco na nuvem) e copiados no aparelho '
          'para uso sem internet. O app só acessa o banco por funções que validam os dados.',
    ]),
    ('Como um alerta nasce', [
      'Clima: quando algum dia previsto atinge o limite. Crítico se o pico passar '
          '${((RegraPrevisao.fatorCritico - 1) * 100).round()}% do limite.',
      'Mobilidade e limpeza: compara a média dos últimos ${RegraAnomalia.diasRecentes} dias '
          'com os ${RegraAnomalia.diasBase} anteriores. O escore z divide a diferença pelo '
          'erro-padrão da média (desvio ÷ √${RegraAnomalia.diasRecentes}). Há alerta a partir '
          'do limite configurado (padrão 2) e é crítico com o dobro.',
      'Lotação, tempo de viagem, sinistros e descarte só geram alerta quando sobem. A coleta '
          'gera alerta quando sobe (lixo acumulado) e quando cai (falha na coleta).',
      'O alerta é identificado pelo primeiro dia do episódio: enquanto o problema durar, '
          'ele continua o mesmo, com a mesma decisão.',
      'O app nunca age: cada alerta espera a decisão de um gestor.',
    ]),
    ('O que os números significam', [
      'Índice de atenção (0–100): média da pressão dos indicadores. Previsão: 0 em 60% '
          'do limite, 100 no limite. Anomalia: 30 no padrão e 70 quando o escore atinge o limite.',
      'Qualidade da evidência (nota de 5 a 95): média dos fatores da regra × peso da fonte '
          '(ao vivo 100%, cache 85%, simulado 60%). Não é probabilidade.',
      'Na anomalia, um dos fatores é o acerto da projeção (MAPE): quanto a suavização '
          'exponencial errou, em média, ao prever o dia seguinte no próprio histórico.',
      'Tendência nos cartões: média dos últimos 7 dias contra a dos 7 anteriores.',
    ]),
    ('Quando não confiar', [
      'Dados simulados ou cache com mais de 24 horas.',
      'Histórico com menos de ${RegraAnomalia.baseMinima + RegraAnomalia.diasRecentes} dias '
          '(a anomalia nem é avaliada).',
      'Previsões para mais de 3 dias.',
      'Base muito variável ou projeção com erro alto.',
      'Feriados, eventos, greves e temporais fora do padrão.',
    ]),
    ('Limitações e vieses', [
      'Um único ponto meteorológico representa todo o Centro.',
      'Quem tem mais acesso à internet relata mais: poucos relatos não significam '
          'poucos problemas.',
      'Regras simples foram escolhidas por serem fáceis de conferir, mas não captam '
          'sazonalidades longas.',
    ]),
    ('Privacidade e acessibilidade', [
      'Aceite explícito antes do uso (LGPD), com a explicação de onde os dados ficam e quem '
          'os vê.',
      'Painéis e alertas abrem sem cadastro. O e-mail só é pedido para relatar e nunca '
          'aparece para outros usuários; no banco, relatos e decisões guardam um código '
          '(hash) no lugar dele.',
      'Sem nome, CPF, telefone ou GPS; dados assim digitados nas descrições são apagados.',
      'Em Ajustes, você apaga seus relatos e o e-mail (no aparelho em que o e-mail foi usado '
          'primeiro).',
      'Modo claro, escuro e alto contraste, texto até 150% e descrições para leitores de tela.',
      'Funciona sem internet, com cópia local e envio posterior.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final estilos = Theme.of(context).textTheme;
    final territorio = TerritorioEscopo.de(context);
    final impacto = territorio.impacto(relatos: RelatosEscopo.de(context).relatos.length);

    return Scaffold(
      appBar: const BarraTopo(title: Text('Como funcionam os números')),
      body: Pagina(
        children: [
          const TituloSecao('Benefício social'),
          Cartao(
            child: Wrap(
              spacing: Espacos.grande,
              runSpacing: Espacos.medio,
              children: [
                _Indicador('Moradores acompanhados', '≈ ${(impacto.moradores / 1000).round()} mil'),
                _Indicador(
                  'Antecedência média',
                  impacto.antecedenciaMedia == null ? '—' : '${Formato.numero(impacto.antecedenciaMedia!)} dias',
                ),
                _Indicador('Alertas já avaliados', Formato.porcento(impacto.taxaDecisao)),
                _Indicador('Relatos de cidadãos', '${impacto.relatos}'),
              ],
            ),
          ),
          const SizedBox(height: Espacos.pequeno),
          Text(
            'Cada dia de antecedência é tempo para montar pontos de hidratação, limpar '
            'canaletas ou reforçar a frota. A taxa de avaliação mostra se os alertas '
            'estão de fato apoiando decisões.',
            style: estilos.bodyMedium?.copyWith(color: cores.suave),
          ),
          for (final (titulo, itens) in _secoes) ...[
            TituloSecao(titulo),
            for (final item in itens)
              Padding(
                padding: const EdgeInsets.only(bottom: Espacos.pequeno),
                child: Text(item, style: estilos.bodyLarge),
              ),
          ],
          const NotaDecisaoHumana(),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Semantics(
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(valor, style: estilos.headlineSmall),
            Text(rotulo, style: estilos.bodySmall?.copyWith(color: Cores.de(context).suave)),
          ],
        ),
      ),
    );
  }
}
