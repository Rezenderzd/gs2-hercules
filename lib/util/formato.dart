abstract final class Formato {
  static const _diasSemana = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];

  static String numero(double valor, {int casas = 1}) {
    return valor.toStringAsFixed(casas).replaceAll('.', ',');
  }

  static String compacto(double valor) {
    return valor == valor.roundToDouble() ? numero(valor, casas: 0) : numero(valor);
  }

  static String variacao(double percentual) {
    final sinal = percentual > 0 ? '+' : '';
    return '$sinal${numero(percentual)}%';
  }

  static String porcento(double razao) => '${(razao * 100).round()}%';

  static String dia(DateTime d) => '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}';

  static String data(DateTime d) => '${dia(d)}/${d.year}';

  static String dataHora(DateTime d) {
    return '${dia(d)}, ${_doisDigitos(d.hour)}h${_doisDigitos(d.minute)}';
  }

  static String diaSemana(DateTime d) => _diasSemana[d.weekday - 1];

  static String diaSemanaCurto(DateTime d) => diaSemana(d).substring(0, 3);

  static String _doisDigitos(int v) => v.toString().padLeft(2, '0');
}
