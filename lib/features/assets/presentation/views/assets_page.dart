import 'package:flutter/material.dart';
import 'asset_form_page.dart';

class AssetsPage extends StatelessWidget {
  final String usuario;

  const AssetsPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrimônio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssetFormPage(usuario: usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'No assets registered yet.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
