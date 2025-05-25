import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';

class GoalFormPage extends StatefulWidget {
  final String usuario;

  const GoalFormPage({super.key, required this.usuario});

  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  IconData? _iconeSelecionado;

  final List<IconData> _iconesDisponiveis = [
    Icons.flag,
    Icons.directions_car,
    Icons.home,
    Icons.card_travel,
    Icons.laptop,
    Icons.favorite,
  ];

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _iconeSelecionado == null) return;

    final nome = _nomeController.text.trim();
    final valor = UtilBrasilFields.converterMoedaParaDouble(_valorController.text);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('goals')
        .add({
      'nome': nome,
      'valor': valor,
      'icone': _iconeSelecionado!.codePoint,
      'criadoEm': DateTime.now().toIso8601String(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Objetivo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                children: _iconesDisponiveis.map((icone) {
                  return GestureDetector(
                    onTap: () => setState(() => _iconeSelecionado = icone),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _iconeSelecionado == icone
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      child: Icon(icone, color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do objetivo'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor da meta (R\$)'),
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
                child: const Text('Salvar Objetivo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
