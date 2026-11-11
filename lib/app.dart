import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'rotas.dart';
import 'state/escopos.dart';
import 'state/preferencias_store.dart';
import 'state/relatos_store.dart';
import 'state/territorio_store.dart';
import 'theme/cores.dart';
import 'theme/tema_visual.dart';

class SaoPauloAtentoApp extends StatefulWidget {
  const SaoPauloAtentoApp({
    super.key,
    required this.preferencias,
    required this.territorio,
    required this.relatos,
  });

  final PreferenciasStore preferencias;
  final TerritorioStore territorio;
  final RelatosStore relatos;

  @override
  State<SaoPauloAtentoApp> createState() => _SaoPauloAtentoAppState();
}

class _SaoPauloAtentoAppState extends State<SaoPauloAtentoApp> {
  late final GoRouter _rotas = criarRotas(widget.preferencias);

  String? _emailAtual;
  bool _gestorAtual = false;

  @override
  void initState() {
    super.initState();
    final preferencias = widget.preferencias;
    _emailAtual = preferencias.email;
    _gestorAtual = preferencias.gestor;
    preferencias.addListener(_aoMudarConta);
    if (preferencias.entrou) preferencias.confirmarConta();
    widget.territorio.carregar();
    widget.relatos.carregar();
  }

  void _aoMudarConta() {
    final preferencias = widget.preferencias;
    final mudouEmail = preferencias.email != _emailAtual;
    final mudouGestor = preferencias.gestor != _gestorAtual;
    _emailAtual = preferencias.email;
    _gestorAtual = preferencias.gestor;
    if (mudouEmail) widget.relatos.carregar();
    if (mudouEmail || mudouGestor) widget.territorio.recarregarDecisoes();
  }

  @override
  void dispose() {
    widget.preferencias.removeListener(_aoMudarConta);
    _rotas.dispose();
    widget.territorio.dispose();
    widget.relatos.dispose();
    widget.preferencias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreferenciasEscopo(
      store: widget.preferencias,
      child: TerritorioEscopo(
        store: widget.territorio,
        child: RelatosEscopo(
          store: widget.relatos,
          child: ListenableBuilder(
            listenable: widget.preferencias,
            builder: (context, _) {
              final preferencias = widget.preferencias;
              return MaterialApp.router(
                title: 'São Paulo Atento',
                debugShowCheckedModeBanner: false,
                theme: TemaVisual.criar(
                  Cores.para(escuro: preferencias.modoEscuro, altoContraste: preferencias.altoContraste),
                ),
                themeAnimationDuration: const Duration(milliseconds: 250),
                routerConfig: _rotas,
                locale: const Locale('pt', 'BR'),
                supportedLocales: const [Locale('pt', 'BR')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (context, child) {
                  final midia = MediaQuery.of(context);
                  final escala = midia.textScaler.scale(1) * preferencias.escalaFonte;
                  return MediaQuery(
                    data: midia.copyWith(textScaler: TextScaler.linear(escala)),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
