import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';

class AssetFormPage extends StatefulWidget {
  final String usuario;
  final String? assetId;
  final Map<String, dynamic>? assetData;

  const AssetFormPage({
    super.key,
    required this.usuario,
    this.assetId,
    this.assetData,
  });

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  String? _tipoSelecionado;
  IconData? _iconeSelecionado;

  final List<IconData> _icones = [
    Icons.home,
    Icons.directions_car,
    Icons.phone_iphone,
    Icons.tv,
    Icons.savings,
    Icons.computer,
  ];

  final List<String> _tipos = ['Imóvel', 'Veículo', 'Eletrônico', 'Investimento', 'Outro'];

  @override
  void initState() {
    super.initState();
    if (widget.assetData != null) {
      _nomeController.text = widget.assetData!['nome'] ?? '';
      _valorController.text = UtilBrasilFields.obterReal(widget.assetData!['valor'] ?? 0);
      _tipoSelecionado = widget.assetData!['tipo'];
      _iconeSelecionado = IconData(widget.assetData!['icone'], fontFamily: 'MaterialIcons');
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _iconeSelecionado == null) return;

    final valor = UtilBrasilFields.converterMoedaParaDouble(_valorController.text);
    final data = {
      'nome': _nomeController.text.trim(),
      'valor': valor,
      'tipo': _tipoSelecionado,
      'icone': _iconeSelecionado!.codePoint,
    };

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('assets');

    if (widget.assetId != null) {
      await ref.doc(widget.assetId).update(data);
    } else {
      await ref.add(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assetId != null ? 'Editar Patrimônio' : 'Novo Patrimônio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Wrap(
                spacing: 12,
                children: _icones.map((icone) {
                  return GestureDetector(
                    onTap: () => setState(() => _iconeSelecionado = icone),
                    child: CircleAvatar(
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
                decoration: const InputDecoration(labelText: 'Nome do bem'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo'),
                value: _tipoSelecionado,
                items: _tipos.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (v) => setState(() => _tipoSelecionado = v),
                validator: (v) => v == null ? 'Selecione o tipo' : null,
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
                validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
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
