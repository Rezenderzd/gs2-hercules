import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sao_paulo_atento/logic/privacidade.dart';
import 'package:sao_paulo_atento/logic/validacao.dart';
import 'package:sao_paulo_atento/models/limites.dart';

void main() {
  group('Descrição do relato', () {
    test('vazia', () {
      expect(Validacao.descricao('  '), 'Conte o que você viu.');
    });

    test('curta diz quantos caracteres faltam', () {
      expect(Validacao.descricao('Lixo na rua'), 'Escreva pelo menos 20 caracteres (faltam 9).');
    });

    test('longa demais', () {
      expect(Validacao.descricao('a' * 301), 'Use no máximo 300 caracteres.');
    });

    test('bloqueia dados pessoais', () {
      expect(
        Validacao.descricao('Lixo acumulado, me chama no 11 99876-5432'),
        contains('Tire telefone'),
      );
    });

    test('aceita texto válido', () {
      expect(Validacao.descricao('Lixo acumulado na esquina da praça'), isNull);
    });
  });

  group('Data da observação', () {
    final agora = DateTime(2026, 11, 8, 14);

    test('obrigatória', () => expect(Validacao.dataObservacao(null, agora), isNotNull));

    test('não aceita futuro', () {
      expect(Validacao.dataObservacao(DateTime(2026, 11, 9), agora), 'A data não pode ser no futuro.');
    });

    test('não aceita mais de 15 dias atrás', () {
      expect(Validacao.dataObservacao(DateTime(2026, 10, 1), agora), isNotNull);
    });

    test('hoje é válido', () => expect(Validacao.dataObservacao(agora, agora), isNull));
  });

  group('Limites numéricos', () {
    test('aceita vírgula', () {
      expect(Validacao.lerNumero('38,5'), 38.5);
      expect(Validacao.numeroNaFaixa('38,5', Limites.faixaSensacao, 'a sensação'), isNull);
    });

    test('rejeita texto', () {
      expect(
        Validacao.numeroNaFaixa('abc', Limites.faixaUv, 'o índice UV'),
        'Digite um número para o índice UV.',
      );
    });

    test('rejeita fora da faixa', () {
      expect(
        Validacao.numeroNaFaixa('1', Limites.faixaEscoreZ, 'o escore z'),
        'Use um valor entre 1,5 e 4 para o escore z.',
      );
    });
  });

  group('E-mail de identificação', () {
    test('aceita formato válido', () => expect(Validacao.email('ana.silva@exemplo.com'), isNull));

    test('recusa vazio e formato inválido', () {
      expect(Validacao.email(''), 'Informe seu e-mail.');
      expect(Validacao.email('ana@'), isNotNull);
    });
  });

  group('Privacidade', () {
    test('remove telefone, e-mail e CPF', () {
      const texto = 'Falar com maria@exemplo.com, (11) 3222-1100 ou CPF 123.456.789-09';
      final limpo = Privacidade.anonimizar(texto);
      expect(limpo, isNot(contains('maria@')));
      expect(limpo, isNot(contains('3222-1100')));
      expect(limpo, isNot(contains('123.456.789-09')));
      expect(limpo, contains(Privacidade.marcador));
    });

    test('mantém texto sem dados pessoais', () {
      const texto = 'Entulho na calçada desde 02/11, perto do número 300.';
      expect(Privacidade.temDadoPessoal(texto), isFalse);
      expect(Privacidade.anonimizar(texto), texto);
    });

    test('número de protocolo com 8 dígitos não é telefone', () {
      expect(Privacidade.temDadoPessoal('Protocolo 12345678 aberto na prefeitura.'), isFalse);
    });

    test('telefone sem DDD, com hífen, é removido', () {
      expect(Privacidade.temDadoPessoal('Liga no 99876-5432'), isTrue);
    });

    test('chave do aparelho tem 32 caracteres hexadecimais', () {
      final a = Privacidade.novaChaveAparelho(Random(1));
      final b = Privacidade.novaChaveAparelho(Random(2));
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(a, isNot(b));
    });
  });
}
