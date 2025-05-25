import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';

class EmergencyReserveFormPage extends StatefulWidget {
  final String usuario;

  const EmergencyReserveFormPage({super.key, required this.usuario});

  @override
  State<EmergencyReserveFormPage> createState() => _EmergencyReserveFormPageState();
}

class _EmergencyReserveFormPageState extends State<EmergencyReserveFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();

  final List<String> _opcoesOrigem = ['Avulsa', 'Bônus'];
  String? _origemSelecionada;

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = UtilBrasilFields.converterMoedaParaDouble(_valorController.text);

    final data = {
      'valor': valor,
      'origem': _origemSelecionada,
      'criadoEm': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('reserva_emergencia')
        .doc('config')
        .collection('lancamentos')
        .add(data);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Origem'),
                value: _origemSelecionada,
                items: _opcoesOrigem.map((op) {
                  return DropdownMenuItem(value: op, child: Text(op));
                }).toList(),
                onChanged: (value) => setState(() => _origemSelecionada = value),
                validator: (value) => value == null ? 'Selecione a origem' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CentavosInputFormatter(moeda: true),
                ],
                validator: (value) =>
                value == null || value.isEmpty ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvar,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
