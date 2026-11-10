import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/territorio.dart';
import '../models/indicador.dart';
import '../models/origem.dart';
import '../models/ponto.dart';
import '../models/serie.dart';
import '../util/datas.dart';

enum MotivoFalhaClima {
  semConexao('Sem conexão com a internet'),
  tempoEsgotado('A Open-Meteo demorou demais para responder'),
  servicoIndisponivel('A Open-Meteo está fora do ar no momento'),
  respostaInvalida('A Open-Meteo respondeu num formato inesperado');

  const MotivoFalhaClima(this.descricao);

  final String descricao;
}

class FalhaClima implements Exception {
  const FalhaClima(this.motivo, [this.detalhe = '']);

  final MotivoFalhaClima motivo;
  final String detalhe;

  @override
  String toString() => 'FalhaClima(${motivo.name}): $detalhe';
}

class OpenMeteoService {
  OpenMeteoService({http.Client? cliente, this.tempoLimite = const Duration(seconds: 10)})
      : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  final Duration tempoLimite;

  static const Map<String, Indicador> _campos = {
    'apparent_temperature_max': Indicadores.sensacao,
    'uv_index_max': Indicadores.uv,
    'precipitation_sum': Indicadores.chuva,
  };

  Uri get _endereco => Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${Territorio.latitude}',
        'longitude': '${Territorio.longitude}',
        'timezone': Territorio.fusoHorario,
        'daily': _campos.keys.join(','),
        'past_days': '30',
        'forecast_days': '7',
      });

  Future<List<Serie>> buscarClima(DateTime agora) async {
    final resposta = await _baixar();
    if (resposta.statusCode == 429 || resposta.statusCode >= 500) {
      throw FalhaClima(MotivoFalhaClima.servicoIndisponivel, 'HTTP ${resposta.statusCode}');
    }
    if (resposta.statusCode != 200) {
      throw FalhaClima(MotivoFalhaClima.respostaInvalida, 'HTTP ${resposta.statusCode}');
    }
    try {
      return _lerSeries(jsonDecode(utf8.decode(resposta.bodyBytes)), agora);
    } on FormatException catch (erro) {
      throw FalhaClima(MotivoFalhaClima.respostaInvalida, erro.message);
    }
  }

  void fechar() => _cliente.close();

  Future<http.Response> _baixar() async {
    try {
      return await _cliente.get(_endereco).timeout(tempoLimite);
    } on TimeoutException {
      throw const FalhaClima(MotivoFalhaClima.tempoEsgotado);
    } on http.ClientException catch (erro) {
      throw FalhaClima(MotivoFalhaClima.semConexao, erro.message);
    } catch (erro) {
      throw FalhaClima(MotivoFalhaClima.semConexao, '$erro');
    }
  }

  List<Serie> _lerSeries(Object? json, DateTime agora) {
    final diario = json is Map<String, dynamic> ? json['daily'] : null;
    if (diario is! Map<String, dynamic>) {
      throw const FormatException('resposta sem o bloco "daily"');
    }
    final datas = [
      for (final texto in (diario['time'] as List<dynamic>? ?? const []))
        if (texto is String) DateTime.parse(texto),
    ];
    final hoje = Datas.soDia(agora);

    return [
      for (final MapEntry(key: campo, value: indicador) in _campos.entries)
        Serie(
          indicador: indicador,
          origem: Origem.aoVivo,
          atualizadaEm: agora,
          pontos: _pontos(diario[campo], datas, hoje, campo),
        ),
    ];
  }

  static List<Ponto> _pontos(Object? valores, List<DateTime> datas, DateTime hoje, String campo) {
    if (valores is! List) throw FormatException('campo "$campo" ausente');
    final pontos = <Ponto>[];
    for (var i = 0; i < datas.length && i < valores.length; i++) {
      final valor = valores[i];
      if (valor is num) {
        pontos.add(Ponto(dia: datas[i], valor: valor.toDouble(), previsto: datas[i].isAfter(hoje)));
      }
    }
    if (pontos.isEmpty) throw FormatException('campo "$campo" sem valores');
    return pontos;
  }
}
