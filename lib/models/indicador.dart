import 'package:flutter/material.dart';

enum Tema {
  calor(
    'Calor e clima',
    'Sensação térmica, índice UV e chuva, com previsão para 7 dias.',
    Icons.wb_sunny_outlined,
  ),
  mobilidade(
    'Mobilidade',
    'Lotação dos ônibus, tempo de viagem e sinistros de trânsito.',
    Icons.directions_bus_outlined,
  ),
  limpeza(
    'Limpeza urbana',
    'Coleta de resíduos, chamados de descarte irregular e relatos.',
    Icons.recycling,
  );

  const Tema(this.titulo, this.descricao, this.icone);

  final String titulo;
  final String descricao;
  final IconData icone;
}

enum RegraAlerta {
  limitePrevisto('Previsão acima do limite'),

  anomalia('Anomalia em relação ao padrão');

  const RegraAlerta(this.rotulo);

  final String rotulo;
}

enum SentidoAnomalia {
  alta('acima'),

  baixa('abaixo'),

  ambos('fora');

  const SentidoAnomalia(this.rotulo);

  final String rotulo;
}

class Indicador {
  const Indicador({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.tema,
    required this.descricao,
    required this.icone,
    required this.fonte,
    required this.regra,
    this.casas = 1,
    this.sentido = SentidoAnomalia.alta,
  });

  final String id;
  final String nome;
  final String unidade;
  final Tema tema;
  final String descricao;
  final IconData icone;
  final String fonte;
  final RegraAlerta regra;
  final int casas;

  final SentidoAnomalia sentido;
}

abstract final class Indicadores {
  static const _openMeteo = 'Open-Meteo (dados reais)';
  static const _simulacao = 'Simulação local (dados sintéticos)';

  static const sensacao = Indicador(
    id: 'sensacao',
    nome: 'Sensação térmica máxima',
    unidade: '°C',
    tema: Tema.calor,
    descricao: 'Temperatura percebida pelo corpo, somando calor e umidade.',
    icone: Icons.thermostat,
    fonte: _openMeteo,
    regra: RegraAlerta.limitePrevisto,
  );

  static const uv = Indicador(
    id: 'uv',
    nome: 'Índice UV máximo',
    unidade: 'UV',
    tema: Tema.calor,
    descricao: 'Intensidade da radiação ultravioleta. Acima de 11 é extremo.',
    icone: Icons.light_mode_outlined,
    fonte: _openMeteo,
    regra: RegraAlerta.limitePrevisto,
  );

  static const chuva = Indicador(
    id: 'chuva',
    nome: 'Chuva no dia',
    unidade: 'mm',
    tema: Tema.calor,
    descricao: 'Chuva acumulada no dia. Volumes altos elevam o risco de '
        'alagamento.',
    icone: Icons.water_drop_outlined,
    fonte: _openMeteo,
    regra: RegraAlerta.limitePrevisto,
  );

  static const lotacao = Indicador(
    id: 'lotacao',
    nome: 'Lotação média dos ônibus',
    unidade: '%',
    tema: Tema.mobilidade,
    descricao: 'Ocupação média das linhas que cruzam o Centro.',
    icone: Icons.groups_outlined,
    fonte: _simulacao,
    regra: RegraAlerta.anomalia,
    casas: 0,
  );

  static const tempoViagem = Indicador(
    id: 'tempo_viagem',
    nome: 'Tempo médio de viagem',
    unidade: 'min',
    tema: Tema.mobilidade,
    descricao: 'Tempo médio das viagens de ônibus até o Centro.',
    icone: Icons.timer_outlined,
    fonte: _simulacao,
    regra: RegraAlerta.anomalia,
    casas: 0,
  );

  static const sinistros = Indicador(
    id: 'sinistros',
    nome: 'Sinistros de trânsito',
    unidade: 'por dia',
    tema: Tema.mobilidade,
    descricao: 'Colisões e atropelamentos registrados por dia.',
    icone: Icons.report_outlined,
    fonte: _simulacao,
    regra: RegraAlerta.anomalia,
    casas: 0,
  );

  static const coleta = Indicador(
    id: 'coleta',
    nome: 'Resíduos coletados',
    unidade: 't',
    tema: Tema.limpeza,
    descricao: 'Toneladas de lixo recolhidas por dia. Queda pode indicar falha '
        'na coleta; alta, lixo acumulado.',
    icone: Icons.delete_outline,
    fonte: _simulacao,
    regra: RegraAlerta.anomalia,
    casas: 0,
    sentido: SentidoAnomalia.ambos,
  );

  static const descarte = Indicador(
    id: 'descarte',
    nome: 'Chamados de descarte irregular',
    unidade: 'por dia',
    tema: Tema.limpeza,
    descricao: 'Pedidos de remoção de lixo e entulho em locais proibidos.',
    icone: Icons.report_gmailerrorred,
    fonte: _simulacao,
    regra: RegraAlerta.anomalia,
    casas: 0,
  );

  static const List<Indicador> todos = [
    sensacao,
    uv,
    chuva,
    lotacao,
    tempoViagem,
    sinistros,
    coleta,
    descarte,
  ];

  static Indicador? porId(String id) => todos.where((i) => i.id == id).firstOrNull;
}
