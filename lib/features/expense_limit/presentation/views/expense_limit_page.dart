import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'expense_limit_form_page.dart';

class ExpenseLimitPage extends StatefulWidget {
  final String usuario;

  const ExpenseLimitPage({super.key, required this.usuario});

  @override
  State<ExpenseLimitPage> createState() => _ExpenseLimitPageState();
}

class _ExpenseLimitPageState extends State<ExpenseLimitPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<DateTime> _meses;

  final List<String> excecoes = [
    'Clubinho Mensal',
    'Aulas',
    'Aluguel',
    'Energia',
    'Água',
    'Internet',
    'Dentista',
    'Podóloga',
    'Academia',
  ];

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _meses = List.generate(6, (i) {
      final data = DateTime(agora.year, agora.month - i);
      return DateTime(data.year, data.month);
    }).reversed.toList();

    _tabController = TabController(length: _meses.length, vsync: this, initialIndex: _meses.length - 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limite de Despesas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _meses.map((data) {
                return Tab(text: DateFormat('MMM yyyy', 'pt_BR').format(data));
              }).toList(),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExpenseLimitFormPage(usuario: widget.usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _meses.map((data) {
          return _buildMes(widget.usuario, data.year, data.month);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.copy),
        label: const Text('Replicar mês anterior'),
        onPressed: () async {
          final agora = DateTime.now();
          final int anoAtual = agora.year;
          final int mesAtual = agora.month;
          final DateTime anterior = DateTime(anoAtual, mesAtual - 1);

          final snapAtual = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.usuario)
              .collection('limite_despesas')
              .where('ano', isEqualTo: anoAtual)
              .where('mes', isEqualTo: mesAtual)
              .get();

          if (snapAtual.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('O mês atual já possui lançamentos.')),
            );
            return;
          }

          double desconto = 0.0;
          final controller = TextEditingController();
          final confirmadoDesconto = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Desconto para novo mês'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Desconto (%)',
                  hintText: 'Ex: 10 para 10%',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );

          if (confirmadoDesconto != true) return;

          desconto = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;

          final confirmarReplicar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirmar replicação'),
              content: const Text('Deseja realmente replicar os limites do mês anterior para o atual?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Sim, replicar'),
                ),
              ],
            ),
          );

          if (confirmarReplicar != true) return;

          final snapAnterior = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.usuario)
              .collection('limite_despesas')
              .where('ano', isEqualTo: anterior.year)
              .where('mes', isEqualTo: anterior.month)
              .get();

          final batch = FirebaseFirestore.instance.batch();

          // Se não houver desconto, replica direto
          if (desconto <= 0) {
            for (var doc in snapAnterior.docs) {
              final data = doc.data();
              final ref = FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.usuario)
                  .collection('limite_despesas')
                  .doc();
              batch.set(ref, {
                'categoria': data['categoria'],
                'subcategoria': data['subcategoria'],
                'valor': data['valor'],
                'ano': anoAtual,
                'mes': mesAtual,
                'criadoEm': DateTime.now().toIso8601String(),
              });
            }
          } else {
            final docs = snapAnterior.docs;
            final docsAjustaveis = docs.where((d) => !excecoes.contains(d['subcategoria'])).toList();
            final docsFixos = docs.where((d) =>  excecoes.contains(d['subcategoria'])).toList();

            final double totalBase = docsAjustaveis.fold(0.0, (soma, d) => soma + ((d['valor'] as num?)?.toDouble() ?? 0.0));
            final double descontoTotal = totalBase * (desconto / 100);

            for (var doc in docsFixos) {
              final data = doc.data();
              final ref = FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.usuario)
                  .collection('limite_despesas')
                  .doc();
              batch.set(ref, {
                'categoria': data['categoria'],
                'subcategoria': data['subcategoria'],
                'valor': data['valor'],
                'ano': anoAtual,
                'mes': mesAtual,
                'criadoEm': DateTime.now().toIso8601String(),
              });
            }

            for (var doc in docsAjustaveis) {
              final data = doc.data();
              final valorOriginal = (data['valor'] as num?)?.toDouble() ?? 0.0;
              final proporcao = valorOriginal / totalBase;
              final descontoProporcional = descontoTotal * proporcao;
              final novoValor = valorOriginal - descontoProporcional;

              final ref = FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.usuario)
                  .collection('limite_despesas')
                  .doc();
              batch.set(ref, {
                'categoria': data['categoria'],
                'subcategoria': data['subcategoria'],
                'valor': novoValor,
                'ano': anoAtual,
                'mes': mesAtual,
                'criadoEm': DateTime.now().toIso8601String(),
              });
            }
          }

          await batch.commit();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Limites replicados com sucesso!')),
            );
          }
        },
      ),
    );
  }

  Widget _buildMes(String usuario, int ano, int mes) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(usuario)
              .collection('limite_despesas')
              .where('ano', isEqualTo: ano)
              .where('mes', isEqualTo: mes)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final orcamentos = snapshot.data!.docs;
        final totalLimite = orcamentos.fold<double>(0.0, (soma, d) {
          return soma + ((d['valor'] as num?)?.toDouble() ?? 0.0);
        });

        return FutureBuilder<double>(
          future: _calcularTotalGastoDoMes(usuario, ano, mes),
          builder: (context, totalGastoSnapshot) {
            final totalGasto = totalGastoSnapshot.data ?? 0.0;

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total do mês:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Limites: ${formatador.format(totalLimite)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gastos: ${formatador.format(totalGasto)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(thickness: 1),
                  ],
                ),
                const SizedBox(height: 12),
                ...orcamentos.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final categoria = data['categoria'] ?? '';
                  final subcategoria = data['subcategoria'] ?? '';
                  final valorOrcado =
                      (data['valor'] as num?)?.toDouble() ?? 0.0;

                  return FutureBuilder<double>(
                    future: _calcularTotalGasto(
                      usuario,
                      categoria,
                      subcategoria,
                      ano,
                      mes,
                    ),
                    builder: (context, gastoSnapshot) {
                      final valorGasto = gastoSnapshot.data ?? 0.0;

                      double percentual = 0.0;
                      double percentualReal = 0.0;

                      if (valorOrcado > 0) {
                        percentualReal = valorGasto / valorOrcado;
                        percentual = percentualReal.clamp(0.0, 1.0);
                      }

                      final int percentualInt = (percentualReal * 100).round();

                      final Color cor =
                          percentualInt >= 95
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
                              Text('Limite: ${formatador.format(valorOrcado)}'),
                              Text('Gasto: ${formatador.format(valorGasto)}'),
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
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Future<double> _calcularTotalGasto(
    String usuario,
    String categoria,
    String subcategoria,
    int ano,
    int mes,
  ) async {
    final despesas =
        await FirebaseFirestore.instance
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

  Future<double> _calcularTotalGastoDoMes(
    String usuario,
    int ano,
    int mes,
  ) async {
    final despesas =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(usuario)
            .collection('despesas')
            .get();

    double total = 0.0;
    for (var doc in despesas.docs) {
      final data = doc.data();
      final dataDespesa = DateTime.tryParse(data['data'] ?? '');
      if (dataDespesa != null &&
          dataDespesa.year == ano &&
          dataDespesa.month == mes) {
        total += (data['valor'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }
}
