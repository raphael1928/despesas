import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';

class ColetarNomePage extends StatefulWidget {
  @override
  _ColetarNomePageState createState() => _ColetarNomePageState();
}

class _ColetarNomePageState extends State<ColetarNomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _carregando = false;
  String? _erro;

  Future<void> _salvarNome() async {
    final nome = _controller.text.trim();

    if (nome.isEmpty) {
      setState(() => _erro = 'Informe um nome');
      return;
    }

    setState(() => _carregando = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nomeUsuario', nome);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MyApp(usuario: nome),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Identifique-se')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Nome de usuário',
                errorText: _erro,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _carregando ? null : _salvarNome,
              child: _carregando
                  ? CircularProgressIndicator()
                  : Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
