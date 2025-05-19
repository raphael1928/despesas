import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/models/recurring_expenses.dart';
import 'recurring_expenses_form_page.dart';
import '../widgets/recurring_expenses_card.dart';

class RecurringExpensesPage extends StatelessWidget {
  final String usuario;

  const RecurringExpensesPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Despesas Recorrentes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecurringExpensesFormPage(usuario: usuario),
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
            .collection('despesas_recorrentes')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final recurringExpenses = docs
              .map((doc) => RecurringExpenses.fromFirestore(doc))
              .toList()
            ..sort((a, b) {
              if (a.isActive == b.isActive) return 0;
              return a.isActive ? -1 : 1;
            });

          return ListView.builder(
            itemCount: recurringExpenses.length,
            itemBuilder: (context, index) {
              return RecurringExpensesCard(
                recurringExpenses: recurringExpenses[index],
                usuario: usuario,
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF6F6F6),
    );
  }
}
