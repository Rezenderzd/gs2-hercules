import '../models/limites.dart';
import '../util/formato.dart';
import 'privacidade.dart';

/// Regras dos formulários: cada função devolve a mensagem de erro ou `null`.
abstract final class Validacao {
  static const int descricaoMinima = 20;
  static const int descricaoMaxima = 300;
  static const int diasRetroativos = 15;

  static final RegExp _formatoEmail = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// E-mail de identificação: só conferimos o formato (não há confirmação).
  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe seu e-mail.';
    if (!_formatoEmail.hasMatch(texto)) return 'Esse e-mail não parece válido. Ex.: nome@exemplo.com';
    return null;
  }

  static String? escolha(Object? valor, String mensagem) {
    return valor == null ? mensagem : null;
  }

  static String? descricao(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Conte o que você viu.';
    if (texto.length < descricaoMinima) {
      return 'Escreva pelo menos $descricaoMinima caracteres '
          '(faltam ${descricaoMinima - texto.length}).';
    }
    if (texto.length > descricaoMaxima) {
      return 'Use no máximo $descricaoMaxima caracteres.';
    }
    if (Privacidade.temDadoPessoal(texto)) {
      return 'Tire telefone, e-mail ou CPF do texto: a descrição fica visível para todos.';
    }
    return null;
  }

  static String? dataObservacao(DateTime? valor, DateTime agora) {
    if (valor == null) return 'Informe o dia em que você viu o problema.';
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dia = DateTime(valor.year, valor.month, valor.day);
    if (dia.isAfter(hoje)) return 'A data não pode ser no futuro.';
    if (hoje.difference(dia).inDays > diasRetroativos) {
      return 'Relate problemas dos últimos $diasRetroativos dias.';
    }
    return null;
  }

  static String? aceite(bool? marcado, String mensagem) {
    return marcado == true ? null : mensagem;
  }

  /// Aceita "38,5" ou "38.5".
  static double? lerNumero(String? valor) {
    final texto = valor?.trim().replaceAll(',', '.') ?? '';
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  static String? numeroNaFaixa(String? valor, Faixa faixa, String nome) {
    final numero = lerNumero(valor);
    if (numero == null) return 'Digite um número para $nome.';
    if (!faixa.contem(numero)) {
      return 'Use um valor entre ${Formato.compacto(faixa.minimo)} e '
          '${Formato.compacto(faixa.maximo)} para $nome.';
    }
    return null;
  }
}
