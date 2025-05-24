import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:intl/intl.dart';

class EmergencyReserveAplicacaoFormPage extends StatefulWidget {
  final String usuario;

  const EmergencyReserveAplicacaoFormPage({super.key, required this.usuario});

  @override
  State<EmergencyReserveAplicacaoFormPage> createState() =>
      _EmergencyReserveAplicacaoFormPageState();
}

class _EmergencyReserveAplicacaoFormPageState
    extends State<EmergencyReserveAplicacaoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  double? _valorTotalAplicado;
  double? _valorTotalLancado;
  final NumberFormat _formatadorReal = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final List<String> _tipos = [
    'Renda Fixa',
    'Fundos de Investimento',
    'Tesouro Direto',
    'Outros',
  ];
  String? _tipoSelecionado;

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final valorNovo = UtilBrasilFields.converterMoedaParaDouble(
      _valorController.text,
    );

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('reserva_emergencia')
        .doc('config');

    // Soma das aplicações já existentes
    final aplicacoesSnapshot = await docRef.collection('aplicacoes').get();
    final somaAplicacoes = aplicacoesSnapshot.docs.fold<double>(
      0.0,
      (total, doc) => total + ((doc['valor'] as num?)?.toDouble() ?? 0.0),
    );

    // Soma dos lançamentos
    final lancamentosSnapshot = await docRef.collection('lancamentos').get();
    final somaLancamentos = lancamentosSnapshot.docs.fold<double>(
      0.0,
      (total, doc) => total + ((doc['valor'] as num?)?.toDouble() ?? 0.0),
    );

    if ((somaAplicacoes + valorNovo) > somaLancamentos) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Limite Excedido'),
          content: Text(
            'O total aplicado (${valorNovo + somaAplicacoes}) '
                'excede o valor disponível (${somaLancamentos.toStringAsFixed(2)}).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // FECHA apenas o AlertDialog
              },
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return;
    }

    // Salvar aplicação
    final data = {
      'tipo': _tipoSelecionado,
      'valor': valorNovo,
      'criadoEm': DateTime.now().toIso8601String(),
    };

    await docRef.collection('aplicacoes').add(data);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _carregarSaldos() async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('reserva_emergencia')
        .doc('config');

    final aplicacoesSnapshot = await docRef.collection('aplicacoes').get();
    final somaAplicacoes = aplicacoesSnapshot.docs.fold<double>(
      0.0,
      (total, doc) => total + ((doc['valor'] as num?)?.toDouble() ?? 0.0),
    );

    final lancamentosSnapshot = await docRef.collection('lancamentos').get();
    final somaLancamentos = lancamentosSnapshot.docs.fold<double>(
      0.0,
      (total, doc) => total + ((doc['valor'] as num?)?.toDouble() ?? 0.0),
    );

    setState(() {
      _valorTotalAplicado = somaAplicacoes;
      _valorTotalLancado = somaLancamentos;
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarSaldos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Aplicação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_valorTotalAplicado != null && _valorTotalLancado != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total já aplicado: ${_formatadorReal.format(_valorTotalAplicado!)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Disponível para aplicar: ${_formatadorReal.format((_valorTotalLancado! - _valorTotalAplicado!).clamp(0, double.infinity))}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Aplicação',
                    ),
                    value: _tipoSelecionado,
                    items:
                        _tipos.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                    onChanged:
                        (value) => setState(() => _tipoSelecionado = value),
                    validator:
                        (value) => value == null ? 'Selecione o tipo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valorController,
                    decoration: const InputDecoration(
                      labelText: 'Valor Aplicado (R\$)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CentavosInputFormatter(moeda: true),
                    ],
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o valor'
                                : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _salvar,
                    child: const Text('Salvar Aplicação'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
