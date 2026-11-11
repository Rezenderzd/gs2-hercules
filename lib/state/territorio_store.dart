import 'package:flutter/foundation.dart';

import '../logic/impacto_social.dart';
import '../logic/indice_atencao.dart';
import '../logic/motor_alertas.dart';
import '../logic/privacidade.dart';
import '../models/alerta.dart';
import '../models/decisao.dart';
import '../models/indicador.dart';
import '../models/limites.dart';
import '../models/origem.dart';
import '../models/serie.dart';
import '../repositories/repositorio_conta.dart';
import '../repositories/repositorio_decisoes.dart';
import '../repositories/repositorio_territorio.dart';
import '../services/banco_local.dart';
import '../services/nuvem/servico_nuvem.dart';
import '../util/mensagens.dart';
import 'preferencias_store.dart';
import 'status_carga.dart';

class TerritorioStore extends ChangeNotifier {
  TerritorioStore({
    required RepositorioTerritorio repositorio,
    required RepositorioDecisoes decisoes,
    required RepositorioConta conta,
    required PreferenciasStore preferencias,
  })  : _repositorio = repositorio,
        _repoDecisoes = decisoes,
        _conta = conta,
        _preferencias = preferencias,
        _limites = preferencias.limites {
    _preferencias.addListener(_aoMudarPreferencias);
  }

  final RepositorioTerritorio _repositorio;
  final RepositorioDecisoes _repoDecisoes;
  final RepositorioConta _conta;
  final PreferenciasStore _preferencias;
  static const _motor = MotorAlertas();

  Limites _limites;
  StatusCarga _status = StatusCarga.inicial;
  String? _erro;
  String? _aviso;
  List<Serie> _series = const [];
  List<Alerta> _alertas = const [];
  List<Pressao> _pressoes = const [];
  Map<String, RegistroDecisao> _decisoes = const {};
  bool _descartado = false;
  bool _falhaAtualizacao = false;

  String? _avisoDecisoes;

  String? get avisoDecisoes => _avisoDecisoes;

  String? get avisoAtualizacao => _falhaAtualizacao
      ? 'Não foi possível atualizar agora. Mostrando os últimos dados carregados.'
      : null;

  bool get podeDecidir => !_repoDecisoes.usaNuvem || _preferencias.gestor;

  bool get podeMudarLimites => !_conta.usaNuvem || _preferencias.gestor;

  static const limiteBanco = Duration(seconds: 10);

  StatusCarga get status => _status;
  bool get carregando => _status == StatusCarga.carregando;
  bool get temDados => _series.isNotEmpty;
  String? get erro => _erro;
  String? get aviso => _aviso;
  List<Serie> get series => _series;
  List<Alerta> get alertas => _alertas;
  List<Pressao> get pressoes => _pressoes;

  double get indiceGeral => IndiceAtencao.geral(_pressoes);

  Origem get origemClima => serie(Indicadores.sensacao.id)?.origem ?? Origem.simulado;

  DateTime? get climaAtualizadoEm => serie(Indicadores.sensacao.id)?.atualizadaEm;

  int get pendentes =>
      _alertas.where((a) => decisaoDe(a.id) == Decisao.aguardando).length;

  Future<void> carregar() async {
    if (carregando) return;
    _status = StatusCarga.carregando;
    _erro = null;
    notifyListeners();
    try {
      final leitura = await _repositorio.carregar();
      final decisoes = await _carregarDecisoes();
      await _sincronizarLimites();
      if (_descartado) return;
      _series = leitura.series;
      _aviso = leitura.aviso;
      _decisoes = decisoes;
      _recalcular();
      _status = StatusCarga.pronto;
      _falhaAtualizacao = false;
    } catch (erro) {
      if (_descartado) return;
      debugPrint('[Território] falha ao carregar: $erro');
      if (temDados) {
        _falhaAtualizacao = true;
        _status = StatusCarga.pronto;
      } else {
        _erro = 'Não conseguimos carregar os dados do Centro agora. '
            'Confira a conexão e tente de novo.';
        _status = StatusCarga.erro;
      }
    }
    notifyListeners();
  }

  Future<void> recarregarDecisoes() async {
    final decisoes = await _carregarDecisoes();
    if (_descartado) return;
    _decisoes = decisoes;
    notifyListeners();
  }

  List<Serie> seriesDo(Tema tema) => _series.where((s) => s.indicador.tema == tema).toList();

  Serie? serie(String indicadorId) =>
      _series.where((s) => s.indicador.id == indicadorId).firstOrNull;

  Alerta? alerta(String id) => _alertas.where((a) => a.id == id).firstOrNull;

  List<Alerta> alertasDo(Tema tema) =>
      _alertas.where((a) => a.indicador.tema == tema).toList();

  List<Alerta> alertasDoIndicador(String indicadorId) =>
      _alertas.where((a) => a.indicador.id == indicadorId).toList();

  double? pressaoDo(String indicadorId) =>
      _pressoes.where((p) => p.indicador.id == indicadorId).firstOrNull?.valor;

  double indiceDo(Tema tema) =>
      IndiceAtencao.geral(_pressoes.where((p) => p.indicador.tema == tema).toList());

  Decisao decisaoDe(String alertaId) => _decisoes[alertaId]?.decisao ?? Decisao.aguardando;

  RegistroDecisao? registroDe(String alertaId) => _decisoes[alertaId];

  Future<bool> decidir(Alerta alerta, Decisao decisao, {String nota = ''}) async {
    final registro = RegistroDecisao(
      alertaId: alerta.id,
      decisao: decisao,
      nota: Privacidade.anonimizar(nota.trim()),
      quando: DateTime.now(),
      tituloAlerta: alerta.titulo,
      indicador: alerta.indicador.nome,
      minha: true,
      pendente: _repoDecisoes.usaNuvem,
    );
    final anterior = _decisoes[alerta.id];
    _decisoes = {..._decisoes, alerta.id: registro};
    notifyListeners();

    const avisoNaFila = 'Sem conexão: a decisão ficou guardada neste aparelho e será '
        'enviada quando a conexão voltar.';
    try {
      final enviada = await _repoDecisoes.salvar(registro, _preferencias.sessao).timeout(limiteBanco);
      _decisoes = {..._decisoes, alerta.id: registro.copiar(pendente: !enviada)};
      _avisoDecisoes = enviada ? null : avisoNaFila;
      return enviada;
    } on FalhaNuvem catch (falha) {
      if (falha.tipo == TipoFalhaNuvem.indisponivel) {
        _avisoDecisoes = avisoNaFila;
        return false;
      }
      final restaurado = {..._decisoes}..remove(alerta.id);
      if (anterior != null) restaurado[alerta.id] = anterior;
      _decisoes = restaurado;
      rethrow;
    } on FalhaArmazenamento {
      _avisoDecisoes = Mensagens.semArmazenamento;
      return false;
    } catch (_) {
      _avisoDecisoes = avisoNaFila;
      return false;
    } finally {
      if (!_descartado) notifyListeners();
    }
  }

  Future<void> salvarLimites(Limites limites) async {
    if (_conta.usaNuvem) {
      final sessao = _preferencias.sessao;
      if (sessao == null || !sessao.gestor) {
        throw const FalhaNuvem(TipoFalhaNuvem.naoAutorizado, 'sessão sem gestor');
      }
      await _conta.salvarLimites(limites, sessao);
    }
    await _preferencias.definirLimites(limites);
  }

  ImpactoSocial impacto({required int relatos}) {
    return ImpactoSocial.calcular(
      alertas: _alertas,
      decisoes: _decisoes,
      relatos: relatos,
      agora: DateTime.now(),
    );
  }

  Future<Map<String, RegistroDecisao>> _carregarDecisoes() async {
    try {
      return await _repoDecisoes.carregar(sessao: _preferencias.sessao).timeout(limiteBanco);
    } catch (_) {
      return _decisoes;
    }
  }

  Future<void> _sincronizarLimites() async {
    try {
      final daNuvem = await _conta.lerLimites().timeout(limiteBanco);
      if (daNuvem != null) await _preferencias.definirLimites(daNuvem);
    } catch (_) {}
  }

  void _aoMudarPreferencias() {
    final novos = _preferencias.limites;
    if (novos == _limites) return;
    _limites = novos;
    if (_series.isEmpty) return;
    _recalcular();
    notifyListeners();
  }

  void _recalcular() {
    _alertas = _motor.avaliar(series: _series, limites: _limites, agora: DateTime.now());
    _pressoes = IndiceAtencao.pressoes(_series, _limites);
  }

  @override
  void dispose() {
    _descartado = true;
    _preferencias.removeListener(_aoMudarPreferencias);
    _repositorio.fechar();
    super.dispose();
  }
}
