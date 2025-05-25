import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'goal_deposit_page.dart';
import 'goal_edit_page.dart';
import 'goal_form_page.dart';
import 'package:intl/intl.dart';

class GoalsPage extends StatelessWidget {
  final String usuario;

  const GoalsPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final goalsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(usuario)
        .collection('goals');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalFormPage(usuario: usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: goalsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Nenhum objetivo cadastrado.'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final nome = data['nome'] ?? 'Sem nome';
              final valor = (data['valor'] as num?)?.toDouble() ?? 0.0;
              final icone = IconData(data['icone'] ?? Icons.flag.codePoint, fontFamily: 'MaterialIcons');

              return StreamBuilder<QuerySnapshot>(
                stream: goalsRef.doc(doc.id).collection('lancamentos').snapshots(),
                builder: (context, lancSnapshot) {
                  final lancDocs = lancSnapshot.data?.docs ?? [];
                  final somaLancamentos = lancDocs.fold<double>(
                    0.0,
                        (total, d) => total + ((d['valor'] as num?)?.toDouble() ?? 0.0),
                  );

                  final percentual = valor > 0 ? (somaLancamentos / valor).clamp(0.0, 1.0) : 0.0;

                  return GestureDetector(
                    onTap: () async {
                      final escolha = await showDialog<String>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('O que deseja fazer?'),
                            content: const Text('Escolha se deseja editar o objetivo ou fazer um lançamento.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop('editar'),
                                child: const Text('Editar Objetivo'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(dialogContext).pop('lancar'),
                                child: const Text('Fazer Lançamento'),
                              ),
                            ],
                          );
                        },
                      );

                      if (escolha == 'editar') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoalEditPage(
                              usuario: usuario,
                              goalId: doc.id,
                              goalData: data,
                            ),
                          ),
                        );
                      } else if (escolha == 'lancar') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoalDepositPage(
                              usuario: usuario,
                              goalId: doc.id,
                            ),
                          ),
                        );
                      }
                    },
                     child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(icone, size: 48), // Ícone maior e centralizado
                              const SizedBox(height: 8),
                              Text(
                                nome,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Meta: ${formatador.format(valor)}',
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: percentual,
                                minHeight: 12, // Mais grosso
                                backgroundColor: Colors.grey.shade300,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatador.format(somaLancamentos),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '${(percentual * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                  );
                },
              );

            },
          );
        },
      ),
    );
  }
}
