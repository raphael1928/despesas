import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GoalDepositPage extends StatefulWidget {
  final String usuario;
  final String goalId;

  const GoalDepositPage({
    super.key,
    required this.usuario,
    required this.goalId,
  });

  @override
  State<GoalDepositPage> createState() => _GoalDepositPageState();
}

class _GoalDepositPageState extends State<GoalDepositPage> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  String? _origemSelecionada;

  final List<String> _opcoesOrigem = ['Avulsa', 'Bônus'];

  double _valorMeta = 0.0;
  double _totalLancado = 0.0;
  bool _carregando = true;

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregarMetaELancamentos();
  }

  Future<void> _carregarMetaELancamentos() async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('goals')
        .doc(widget.goalId);

    final metaSnap = await docRef.get();
    _valorMeta = (metaSnap.data()?['valor'] as num?)?.toDouble() ?? 0.0;

    final lancSnapshot = await docRef.collection('lancamentos').get();
    _totalLancado = lancSnapshot.docs.fold<double>(
      0.0,
      (soma, d) => soma + ((d['valor'] as num?)?.toDouble() ?? 0.0),
    );

    setState(() {
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _origemSelecionada == null)
      return;

    final valor = UtilBrasilFields.converterMoedaParaDouble(
      _valorController.text,
    );
    final disponivel = (_valorMeta - _totalLancado).clamp(0, double.infinity);

    if (valor > disponivel) {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Valor excedido'),
              content: Text(
                'Você só pode lançar até ${_formatador.format(disponivel)}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Ok'),
                ),
              ],
            ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('goals')
        .doc(widget.goalId)
        .collection('lancamentos')
        .add({
          'valor': valor,
          'origem': _origemSelecionada,
          'criadoEm': DateTime.now().toIso8601String(),
        });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final disponivel = (_valorMeta - _totalLancado).clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Lançamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total já lançado: ${_formatador.format(_totalLancado)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Disponível para lançar: ${_formatador.format(disponivel)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Origem'),
                    value: _origemSelecionada,
                    items:
                        _opcoesOrigem.map((op) {
                          return DropdownMenuItem(value: op, child: Text(op));
                        }).toList(),
                    onChanged:
                        (value) => setState(() => _origemSelecionada = value),
                    validator:
                        (value) => value == null ? 'Selecione a origem' : null,
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
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o valor'
                                : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _salvar,
                    child: const Text('Salvar Lançamento'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Lançamentos realizados:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.usuario)
                      .collection('goals')
                      .doc(widget.goalId)
                      .collection('lancamentos')
                      .orderBy('criadoEm', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text('Nenhum lançamento ainda.');
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    final valor = (data['valor'] as num?)?.toDouble() ?? 0.0;
                    final origem = data['origem'] ?? '---';
                    final dataStr =
                        data['criadoEm']?.toString().split('T').first ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor)}',
                      ),
                      subtitle: Text('Origem: $origem • $dataStr'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('Excluir lançamento'),
                                  content: const Text(
                                    'Deseja excluir este lançamento?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.of(ctx).pop(true),
                                      child: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                          );

                          if (confirmar == true) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.usuario)
                                .collection('goals')
                                .doc(widget.goalId)
                                .collection('lancamentos')
                                .doc(id)
                                .delete();
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
