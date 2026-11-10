/// Operações de calendário usadas em dados, regras e telas.
abstract final class Datas {
  static DateTime soDia(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Soma dias pelo calendário (sem problemas com horário de verão).
  static DateTime somarDias(DateTime d, int dias) {
    return DateTime(d.year, d.month, d.day + dias);
  }

  /// Dias desde 01/01/1970, independente de fuso.
  static int diaEpoca(DateTime d) {
    return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  /// Formato `AAAA-MM-DD`, usado em identificadores estáveis.
  static String iso(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }
}
