import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/subscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionFormPage extends StatefulWidget {
  final Subscription? subscription;
  final String usuario;

  const SubscriptionFormPage({
    super.key,
    this.subscription,
    required this.usuario,
  });

  @override
  State<SubscriptionFormPage> createState() => _SubscriptionFormPageState();
}

class _SubscriptionFormPageState extends State<SubscriptionFormPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedType;
  DateTime? _signUpDate;
  bool _isActive = true;

  final List<String> _types = [
    'Netflix',
    'Max',
    'Disney+',
    'YouTube Premium',
    'Prime',
    'HBO Max',
    'ChatGPT',
    'ifood Club',
    'Linkedin',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _selectedType = widget.subscription!.name;
      _signUpDate = widget.subscription!.signUpDate;
      _isActive = widget.subscription!.isActive;
    }
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate() && _signUpDate != null) {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.usuario)
          .collection('assinaturas');

      final data = {
        'tipo': _selectedType,
        'dataAssinatura': _signUpDate!.toIso8601String(),
        'ativo': _isActive,
      };

      if (widget.subscription == null) {
        await collection.add(data);
      } else {
        await collection.doc(widget.subscription!.id).update(data);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subscription == null ? 'Nova Assinatura' : 'Editar Assinatura')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: InputDecoration(labelText: 'Tipo de assinatura'),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) => value == null ? 'Selecione um tipo' : null,
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_signUpDate != null
                    ? 'Data de assinatura: ${DateFormat('dd/MM/yyyy').format(_signUpDate!)}'
                    : 'Selecionar data de assinatura'),
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
