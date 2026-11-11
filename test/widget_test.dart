import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sao_paulo_atento/models/ponto.dart';
import 'package:sao_paulo_atento/services/preferencias_service.dart';
import 'package:sao_paulo_atento/state/escopos.dart';
import 'package:sao_paulo_atento/state/preferencias_store.dart';
import 'package:sao_paulo_atento/theme/cores.dart';
import 'package:sao_paulo_atento/theme/tema_visual.dart';
import 'package:sao_paulo_atento/widgets/base.dart';
import 'package:sao_paulo_atento/widgets/campos.dart';
import 'package:sao_paulo_atento/widgets/estados.dart';
import 'package:sao_paulo_atento/widgets/graficos.dart';

Widget montar(Widget filho, {Cores cores = Cores.claro}) {
  return MaterialApp(
    theme: TemaVisual.criar(cores),
    home: Scaffold(body: SingleChildScrollView(child: filho)),
  );
}

void main() {
  testWidgets('nota de decisão humana aparece nos modos claro e escuro', (tester) async {
    for (final cores in [Cores.claro, Cores.escuro]) {
      await tester.pumpWidget(montar(const NotaDecisaoHumana(), cores: cores));
      expect(find.textContaining('não substituem, a decisão humana'), findsOneWidget);
    }
  });

  testWidgets('estado de erro oferece tentar de novo', (tester) async {
    var tentou = false;
    await tester.pumpWidget(montar(EstadoTela.erro(texto: 'Sem rede', aoTentar: () => tentou = true)));
    await tester.tap(find.text('Tentar de novo'));
    expect(tentou, isTrue);
  });

  testWidgets('gráfico descreve os dados para o leitor de tela', (tester) async {
    final pontos = [
      for (var i = 1; i <= 5; i++) Ponto(dia: DateTime(2026, 11, i), valor: i * 10.0),
    ];
    await tester.pumpWidget(
      montar(GraficoLinha(pontos: pontos, descricao: 'Lotação', unidade: '%', casas: 0, referencias: const [45])),
    );
    expect(find.bySemanticsLabel(RegExp('Lotação: 5 dias, entre 10 e 50 %')), findsOneWidget);
  });

  testWidgets('campo de escolha exige uma opção', (tester) async {
    final formulario = GlobalKey<FormState>();
    await tester.pumpWidget(
      montar(
        Form(
          key: formulario,
          child: CampoEscolha<String>(
            rotulo: 'Onde?',
            opcoes: const ['Sé', 'República'],
            textoDe: (b) => b,
            validator: (v) => v == null ? 'Escolha o bairro.' : null,
          ),
        ),
      ),
    );
    expect(formulario.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Escolha o bairro.'), findsOneWidget);

    await tester.tap(find.text('Sé'));
    await tester.pump();
    expect(formulario.currentState!.validate(), isTrue);
  });

  testWidgets('ícone de lua e sol alterna o modo escuro', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferenciasStore(PreferenciasService(await SharedPreferences.getInstance()));
    await tester.pumpWidget(
      PreferenciasEscopo(store: store, child: montar(const BotaoModo())),
    );

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.tap(find.byType(BotaoModo));
    await tester.pumpAndSettle();
    expect(store.modoEscuro, isTrue);
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });
}
