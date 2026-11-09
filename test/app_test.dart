import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sao_paulo_atento/app.dart';
import 'package:sao_paulo_atento/theme/cores.dart';

void main() {
  testWidgets('app abre mostrando o nome do projeto', (tester) async {
    await tester.pumpWidget(const SaoPauloAtentoApp());
    expect(find.text('São Paulo Atento'), findsWidgets);
  });

  testWidgets('ícone de lua e sol alterna o modo escuro', (tester) async {
    await tester.pumpWidget(const SaoPauloAtentoApp());
    Brightness brilho() => Cores.de(tester.element(find.byType(Scaffold))).brilho;
    expect(brilho(), Brightness.light);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(brilho(), Brightness.dark);
  });
}
