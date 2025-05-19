import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';

import '../../../recurring_expenses/domain/models/recurring_expenses.dart';

class RecurringExpensesFormPage extends StatefulWidget {
  final RecurringExpenses? recurringExpenses;
  final String usuario;

  const RecurringExpensesFormPage({
    super.key,
    this.recurringExpenses,
    required this.usuario,
  });

  @override
  State<RecurringExpensesFormPage> createState() => _RecurringExpensesFormPageState();
}

class _RecurringExpensesFormPageState extends State<RecurringExpensesFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _valorController = TextEditingController();
  String? _selectedType;
  DateTime? _signUpDate;
  bool _isActive = true;

  final List<String> _types = [
    'Aluguel',
    'Energia',
    'Água',
    'Internet',
    'Telefone',
    'Dentista',
    'Beach Tennis Arena',
    'Beach Tennis Aulas',
    'Carro',
    'Lote',
    'Condomínio',
    'IPVA',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recurringExpenses != null) {
      _selectedType = widget.recurringExpenses!.name;
      _signUpDate = widget.recurringExpenses!.signUpDate;
      _isActive = widget.recurringExpenses!.isActive;
      _valorController.text = widget.recurringExpenses!.valor
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    }
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate() && _signUpDate != null) {
      final valor = UtilBrasilFields.converterMoedaParaDouble(_valorController.text);

      final data = {
        'tipo': _selectedType,
        'dataVencimento': _signUpDate!.toIso8601String(),
        'ativo': _isActive,
        'valor': valor,
      };

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.usuario)
          .collection('despesas_recorrentes');

      print('🟢 Salvando em: users/${widget.usuario}/despesas_recorrentes');

      if (widget.recurringExpenses == null) {
        await docRef.add(data);
      } else {
        await docRef.doc(widget.recurringExpenses!.id).update(data);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _signUpDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _signUpDate = data);
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recurringExpenses == null ? 'Nova Despesa' : 'Editar Despesa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: InputDecoration(labelText: 'Tipo de despesa'),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) => value == null ? 'Selecione um tipo' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CentavosInputFormatter(moeda: true),
                ],
                validator: (value) =>
                value == null || value.isEmpty ? 'Informe o valor' : null,
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_signUpDate != null
                    ? 'Data de vencimento: ${DateFormat('dd/MM/yyyy').format(_signUpDate!)}'
                    : 'Selecionar data de vencimento'),
                trailing: Icon(Icons.calendar_today),
                onTap: _selecionarData,
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Ativo'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvar,
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
