import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/cores.dart';
import '../theme/espacos.dart';

class _Erro extends StatelessWidget {
  const _Erro(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: Espacos.pequeno),
        child: Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Cores.de(context).critico),
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacos.entre),
      child: Semantics(header: true, child: Text(texto, style: Theme.of(context).textTheme.titleMedium)),
    );
  }
}

/// Campo de texto com borda fina.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.rotulo,
    this.controlador,
    this.dica,
    this.ajuda,
    this.sufixo,
    this.validar,
    this.numerico = false,
    this.tipo,
    this.linhas = 1,
    this.maximo,
    this.habilitado = true,
  });

  final String rotulo;
  final TextEditingController? controlador;
  final String? dica;
  final String? ajuda;
  final String? sufixo;
  final FormFieldValidator<String>? validar;
  final bool numerico;

  /// Teclado específico (ex.: e-mail). Se nulo, é escolhido pelo contexto.
  final TextInputType? tipo;
  final int linhas;
  final int? maximo;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    OutlineInputBorder borda(Color cor, [double largura = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Espacos.raio),
          borderSide: BorderSide(color: cor, width: largura),
        );
    return TextFormField(
      controller: controlador,
      enabled: habilitado,
      validator: validar,
      maxLines: linhas,
      maxLength: maximo,
      keyboardType: tipo ??
          (numerico
              ? const TextInputType.numberWithOptions(decimal: true)
              : (linhas > 1 ? TextInputType.multiline : TextInputType.text)),
      inputFormatters: numerico ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        helperText: ajuda,
        helperMaxLines: 3,
        errorMaxLines: 3,
        suffixText: sufixo,
        border: borda(cores.linha),
        enabledBorder: borda(cores.linha),
        focusedBorder: borda(cores.destaque, 2),
        errorBorder: borda(cores.critico),
        focusedErrorBorder: borda(cores.critico, 2),
      ),
    );
  }
}

/// Escolha única com chips, integrada ao `Form`.
class CampoEscolha<T> extends FormField<T> {
  CampoEscolha({
    super.key,
    required String rotulo,
    required List<T> opcoes,
    required String Function(T) textoDe,
    super.validator,
    super.onSaved,
  }) : super(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (campo) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Rotulo(rotulo),
              Wrap(
                spacing: Espacos.pequeno,
                runSpacing: Espacos.pequeno,
                children: [
                  for (final opcao in opcoes)
                    ChoiceChip(
                      label: Text(textoDe(opcao)),
                      selected: campo.value == opcao,
                      onSelected: (_) => campo.didChange(opcao),
                    ),
                ],
              ),
              if (campo.hasError) _Erro(campo.errorText ?? ''),
            ],
          ),
        );
}

/// Data com botão que abre o calendário, integrada ao `Form`.
class CampoData extends FormField<DateTime> {
  CampoData({
    super.key,
    required String rotulo,
    required String Function(DateTime) textoDe,
    required Future<DateTime?> Function(BuildContext, DateTime?) escolher,
    super.initialValue,
    super.validator,
    super.onSaved,
  }) : super(
          builder: (campo) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Rotulo(rotulo),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(campo.value == null ? 'Escolher o dia' : textoDe(campo.value!)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(Espacos.toque, Espacos.toque)),
                onPressed: () async {
                  final escolhida = await escolher(campo.context, campo.value);
                  if (escolhida != null) campo.didChange(escolhida);
                },
              ),
              if (campo.hasError) _Erro(campo.errorText ?? ''),
            ],
          ),
        );
}

/// Caixa de aceite integrada ao `Form`.
class CampoAceite extends FormField<bool> {
  CampoAceite({super.key, required String texto, super.validator})
      : super(
          initialValue: false,
          builder: (campo) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: campo.value ?? false,
                onChanged: (v) => campo.didChange(v ?? false),
                title: Text(texto),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (campo.hasError) _Erro(campo.errorText ?? ''),
            ],
          ),
        );
}
