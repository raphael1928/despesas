import 'package:flutter/material.dart';

class BudgetGoalFormPage extends StatelessWidget {
  final String usuario;

  const BudgetGoalFormPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Meta Orçamentária')),
      body: const Center(
        child: Text(
          'Form for defining budget goals will go here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
