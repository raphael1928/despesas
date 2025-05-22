import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';

class MonthlyBudgetFormPage extends StatefulWidget {
  final String usuario;

  const MonthlyBudgetFormPage({super.key, required this.usuario});

  @override
  State<MonthlyBudgetFormPage> createState() => _MonthlyBudgetFormPageState();
}

class _MonthlyBudgetFormPageState extends State<MonthlyBudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();

  List<String> _categorias = [];
  List<String> _subcategorias = [];

  String? _categoriaSelecionada;
  String? _subcategoriaSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    final snapshot = await FirebaseFirestore.instance.collection('categorias').get();
    final categorias = snapshot.docs.map((doc) => doc.id).toList();
    setState(() => _categorias = categorias);
  }

  Future<void> _carregarSubcategorias(String categoria) async {
    final doc = await FirebaseFirestore.instance.collection('categorias').doc(categoria).get();
    final data = doc.data();
    final lista = (data?['subcategorias'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    setState(() {
      _subcategorias = lista;
      _subcategoriaSelecionada = null;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = UtilBrasilFields.converterMoedaParaDouble(_valorController.text);
    final agora = DateTime.now();

    final data = {
      'categoria': _categoriaSelecionada,
      'subcategoria': _subcategoriaSelecionada,
      'valor': valor,
      'ano': agora.year,
      'mes': agora.month,
      'criadoEm': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('orcamento_mensal')
        .add(data);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Orçamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoria'),
                value: _categoriaSelecionada,
                items: _categorias.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() => _categoriaSelecionada = value);
                  if (value != null) _carregarSubcategorias(value);
                },
                validator: (value) => value == null ? 'Selecione uma categoria' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Subcategoria'),
                value: _subcategoriaSelecionada,
                items: _subcategorias.map((sub) {
                  return DropdownMenuItem(value: sub, child: Text(sub));
                }).toList(),
                onChanged: (value) => setState(() => _subcategoriaSelecionada = value),
                validator: (value) => value == null ? 'Selecione uma subcategoria' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor planejado (R\$)'),
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
