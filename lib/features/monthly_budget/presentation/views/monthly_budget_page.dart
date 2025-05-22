import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'monthly_budget_form_page.dart';

class MonthlyBudgetPage extends StatelessWidget {
  final String usuario;

  const MonthlyBudgetPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final ano = agora.year;
    final mes = agora.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamento Mensal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MonthlyBudgetFormPage(usuario: usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(usuario)
            .collection('orcamento_mensal')
            .where('ano', isEqualTo: ano)
            .where('mes', isEqualTo: mes)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orcamentos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orcamentos.length,
            itemBuilder: (context, index) {
              final doc = orcamentos[index];
              final data = doc.data() as Map<String, dynamic>;
              final categoria = data['categoria'] ?? '';
              final subcategoria = data['subcategoria'] ?? '';
              final valorOrcado = (data['valor'] as num?)?.toDouble() ?? 0.0;

              return FutureBuilder<double>(
                future: _calcularTotalGasto(usuario, categoria, subcategoria, ano, mes),
                builder: (context, gastoSnapshot) {
                  final valorGasto = gastoSnapshot.data ?? 0.0;

                  double percentual = 0.0;
                  double percentualReal = 0.0;

                  if (valorOrcado > 0) {
                    percentualReal = valorGasto / valorOrcado;
                    percentual = percentualReal.clamp(0.0, 1.0);
                  }

                  final int percentualInt = (percentualReal * 100).round();

                  final Color cor = percentualInt >= 95
                      ? Colors.red
                      : percentualInt >= 81
                      ? Colors.amber
                      : Colors.green;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$categoria - $subcategoria',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Orçado: R\$ ${valorOrcado.toStringAsFixed(2)}'),
                          const SizedBox(height: 4),
                          Text('Gasto: R\$ ${valorGasto.toStringAsFixed(2)}'),
                          const SizedBox(height: 4),
                          Text('Percentual: $percentualInt%'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentual,
                            backgroundColor: Colors.grey.shade300,
                            color: cor,
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<double> _calcularTotalGasto(
      String usuario,
      String categoria,
      String subcategoria,
      int ano,
      int mes,
      ) async {
    final despesas = await FirebaseFirestore.instance
        .collection('users')
        .doc(usuario)
        .collection('despesas')
        .get();

    double total = 0.0;

    for (var doc in despesas.docs) {
      final data = doc.data();
      final dataDespesa = DateTime.tryParse(data['data'] ?? '');
      if (dataDespesa == null) continue;

      final mesmaCategoria = data['categoria'] == categoria;
      final mesmaSubcategoria = data['subcategoria'] == subcategoria;
      final mesmoMes = dataDespesa.year == ano && dataDespesa.month == mes;

      if (mesmoMes && mesmaCategoria && mesmaSubcategoria) {
        total += (data['valor'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return total;
  }
}
