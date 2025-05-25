import 'package:flutter/material.dart';

class AssetFormPage extends StatelessWidget {
  final String usuario;

  const AssetFormPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Patrimônio')),
      body: const Center(
        child: Text(
          'Asset registration form coming soon.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
