import 'package:flutter/widgets.dart';

import 'preferencias_store.dart';
import 'relatos_store.dart';
import 'territorio_store.dart';

class PreferenciasEscopo extends InheritedNotifier<PreferenciasStore> {
  const PreferenciasEscopo({super.key, required PreferenciasStore store, required super.child})
      : super(notifier: store);

  static PreferenciasStore de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<PreferenciasEscopo>();
    assert(escopo != null, 'PreferenciasEscopo não encontrado acima deste widget.');
    return escopo!.notifier!;
  }
}

class TerritorioEscopo extends InheritedNotifier<TerritorioStore> {
  const TerritorioEscopo({super.key, required TerritorioStore store, required super.child})
      : super(notifier: store);

  static TerritorioStore de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<TerritorioEscopo>();
    assert(escopo != null, 'TerritorioEscopo não encontrado acima deste widget.');
    return escopo!.notifier!;
  }
}

class RelatosEscopo extends InheritedNotifier<RelatosStore> {
  const RelatosEscopo({super.key, required RelatosStore store, required super.child})
      : super(notifier: store);

  static RelatosStore de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<RelatosEscopo>();
    assert(escopo != null, 'RelatosEscopo não encontrado acima deste widget.');
    return escopo!.notifier!;
  }
}
