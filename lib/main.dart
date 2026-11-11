import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'app.dart';
import 'config/nuvem.dart';
import 'repositories/repositorio_conta.dart';
import 'repositories/repositorio_decisoes.dart';
import 'repositories/repositorio_relatos.dart';
import 'repositories/repositorio_territorio.dart';
import 'services/banco_local.dart';
import 'services/nuvem/nuvem_supabase.dart';
import 'services/nuvem/servico_nuvem.dart';
import 'services/open_meteo_service.dart';
import 'services/preferencias_service.dart';
import 'services/simulador_service.dart';
import 'state/preferencias_store.dart';
import 'state/relatos_store.dart';
import 'state/territorio_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final nuvem = await _conectarNuvem();
  final banco = BancoLocal();
  final conta = RepositorioConta(nuvem: nuvem);
  final preferencias = PreferenciasStore(
    PreferenciasService(await SharedPreferences.getInstance()),
    conta: conta,
  );
  final territorio = TerritorioStore(
    repositorio: RepositorioTerritorio(
      openMeteo: OpenMeteoService(),
      simulador: const SimuladorService(),
      banco: banco,
    ),
    decisoes: RepositorioDecisoes(banco, nuvem: nuvem),
    conta: conta,
    preferencias: preferencias,
  );
  final relatos = RelatosStore(
    repositorio: RepositorioRelatos(banco, nuvem: nuvem),
    preferencias: preferencias,
  );

  runApp(SaoPauloAtentoApp(preferencias: preferencias, territorio: territorio, relatos: relatos));
}

Future<ServicoNuvem?> _conectarNuvem() async {
  if (!ConfigNuvem.configurada) return null;
  try {
    await Supabase.initialize(
      url: ConfigNuvem.urlBase,
      publishableKey: ConfigNuvem.chaveAnonima,
    );
    return NuvemSupabase(Supabase.instance.client);
  } catch (_) {
    return null;
  }
}
