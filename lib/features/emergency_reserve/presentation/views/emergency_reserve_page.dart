import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'emergency_reserve_aplicacao_form_page.dart';
import 'emergency_reserve_form_page.dart';

class EmergencyReservePage extends StatefulWidget {
  final String usuario;

  const EmergencyReservePage({super.key, required this.usuario});

  @override
  State<EmergencyReservePage> createState() => _EmergencyReservePageState();
}

class _EmergencyReservePageState extends State<EmergencyReservePage> {
  double? valorIdeal;
  double totalAcumulado = 0.0;
  final Map<String, double> _valoresPorTipo = {};
  final NumberFormat _formatadorReal = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('reserva_emergencia')
        .doc('config');

    final configSnapshot = await docRef.get();

    if (!configSnapshot.exists) {
      await _mostrarDialogValorIdeal(docRef);
      return;
    }

    final ideal = (configSnapshot.data()?['valorIdeal'] as num?)?.toDouble() ?? 0.0;

    // Total acumulado = soma dos lançamentos
    final lancamentosSnapshot = await docRef.collection('lancamentos').get();
    double somaLancamentos = 0.0;
    for (var doc in lancamentosSnapshot.docs) {
      final valor = (doc['valor'] as num?)?.toDouble() ?? 0.0;
      somaLancamentos += valor;
    }

    // Aplicações por tipo
    final aplicacoesSnapshot = await docRef.collection('aplicacoes').get();
    _valoresPorTipo.clear();

    for (var doc in aplicacoesSnapshot.docs) {
      final valor = (doc['valor'] as num?)?.toDouble() ?? 0.0;
      final tipo = doc['tipo'] ?? 'Outros';

      _valoresPorTipo[tipo] = (_valoresPorTipo[tipo] ?? 0.0) + valor;
    }

    setState(() {
      valorIdeal = ideal;
      totalAcumulado = somaLancamentos;
    });
  }

  Future<void> _mostrarDialogValorIdeal(DocumentReference docRef) async {
    final controller = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Reserva'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Valor ideal da reserva (R\$)'),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CentavosInputFormatter(moeda: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmado == true && controller.text.isNotEmpty) {
      final valor = UtilBrasilFields.converterMoedaParaDouble(controller.text);
      await docRef.set({'valorIdeal': valor});
      setState(() {
        valorIdeal = valor;
      });
      await _carregarDados();
    } else {
      Navigator.of(context).pop();
    }
  }

  Color _corPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'renda fixa':
        return Colors.teal;
      case 'fundos de investimento':
        return Colors.green;
      case 'tesouro direto':
        return Colors.amber.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double meta = valorIdeal ?? 1;
    final double percentual = (totalAcumulado / meta).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva de Emergência'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmergencyReserveFormPage(usuario: widget.usuario),
                ),
              );
              _carregarDados();
            },
          ),
        ],
      ),
      body: valorIdeal == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              height: 340, // ainda maior que antes
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: [
                        ..._valoresPorTipo.entries.map((entry) {
                          final tipo = entry.key;
                          final valor = entry.value;
                          final percent = (valor / valorIdeal!) * 100;

                          return PieChartSectionData(
                            color: _corPorTipo(tipo),
                            value: valor,
                            title: '${percent.toStringAsFixed(0)}%',
                            radius: 100, // AUMENTADO
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                        if (totalAcumulado < valorIdeal!)
                          PieChartSectionData(
                            color: Colors.grey.shade300,
                            value: (valorIdeal! - totalAcumulado).clamp(0, valorIdeal!),
                            title: '',
                            radius: 100, // MESMO RAIO PARA COERÊNCIA
                          ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 90, // MAIOR BURACO CENTRAL
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatadorReal.format(totalAcumulado),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Falta ${_formatadorReal.format((valorIdeal! - totalAcumulado).clamp(0, double.infinity))}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ..._valoresPorTipo.entries.map((entry) {
              final tipo = entry.key;
              final valor = entry.value;
              final percentualTipo = ((valor / totalAcumulado) * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAplicacaoTile(
                  '$tipo - ${_formatadorReal.format(valor)} ($percentualTipo%)',
                  _corPorTipo(tipo),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.account_balance_wallet_outlined),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmergencyReserveAplicacaoFormPage(usuario: widget.usuario),
            ),
          );
          _carregarDados();
        },
      ),
    );
  }

  Widget _buildAplicacaoTile(String label, Color cor) {
    return Container(
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      width: double.infinity,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
