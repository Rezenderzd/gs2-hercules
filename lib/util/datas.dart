abstract final class Datas {
  static DateTime soDia(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime somarDias(DateTime d, int dias) {
    return DateTime(d.year, d.month, d.day + dias);
  }

  static int diaEpoca(DateTime d) {
    return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  static String iso(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }
}
