/// Território acompanhado pelo São Paulo Atento.
///
/// Tudo o que é específico do lugar fica aqui: trocar de bairro ou cidade
/// exige mudar apenas este arquivo.
abstract final class Territorio {
  static const String nome = 'Centro de São Paulo';
  static const String detalhe = 'São Paulo · SP · Subprefeitura Sé';

  /// Coordenadas usadas nas consultas à Open-Meteo (Praça da Sé).
  static const double latitude = -23.5505;
  static const double longitude = -46.6333;
  static const String fusoHorario = 'America/Sao_Paulo';

  /// População aproximada da região (estimativa para fins acadêmicos),
  /// usada nos indicadores de benefício social.
  static const int moradoresEstimados = 430000;

  /// Bairros disponíveis no relato do cidadão. O app nunca guarda endereço
  /// nem GPS: o bairro é a menor localização registrada.
  static const List<String> bairros = [
    'Sé',
    'República',
    'Bela Vista',
    'Bom Retiro',
    'Cambuci',
    'Consolação',
    'Liberdade',
    'Santa Cecília',
  ];
}
