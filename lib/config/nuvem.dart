abstract final class ConfigNuvem {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String chaveAnonima = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get configurada => url.isNotEmpty && chaveAnonima.isNotEmpty;

  static String get urlBase {
    var base = url.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.endsWith('/rest/v1')) base = base.substring(0, base.length - '/rest/v1'.length);
    return base;
  }
}
