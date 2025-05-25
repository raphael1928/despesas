import 'package:flutter/material.dart';
import 'budget_goal_form_page.dart';

class BudgetGoalsPage extends StatelessWidget {
  final String usuario;

  const BudgetGoalsPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas Orçamentárias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudgetGoalFormPage(usuario: usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'No budget goals defined yet.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
