import 'package:flutter_test/flutter_test.dart';
import 'package:sao_paulo_atento/app.dart';

void main() {
  testWidgets('app abre mostrando o nome do projeto', (tester) async {
    await tester.pumpWidget(const SaoPauloAtentoApp());
    expect(find.text('São Paulo Atento'), findsWidgets);
  });
}
