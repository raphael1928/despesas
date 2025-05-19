import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RelatorioPage extends StatefulWidget {
  @override
  _RelatorioPageState createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  DateTime _dataInicial = DateTime.now().subtract(Duration(days: 7));
  DateTime _dataFinal = DateTime.now();
  String? _nomeUsuario;
  Map<String, Map<String, double>> _totaisPorCategoria = {};
  double _totalGeral = 0.0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _nomeUsuario = prefs.getString('nomeUsuario');
    if (_nomeUsuario != null) {
      _carregarRelatorio();
    }
  }

  Future<void> _carregarRelatorio() async {
    setState(() => _carregando = true);

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_nomeUsuario)
        .collection('despesas');

    final snapshot = await ref
        .where('data', isGreaterThanOrEqualTo: _formatarData(_dataInicial))
        .where('data', isLessThanOrEqualTo: _formatarData(_dataFinal))
        .get();

    final Map<String, Map<String, double>> agrupado = {};
    double total = 0.0;

    for (var doc in snapshot.docs) {
      String categoria = doc['categoria'];
      String subcategoria = doc['subcategoria'];
      double valor = (doc['valor'] as num).toDouble();

      agrupado.putIfAbsent(categoria, () => {});
      agrupado[categoria]!.update(subcategoria, (v) => v + valor, ifAbsent: () => valor);
      total += valor;
    }

    setState(() {
      _totaisPorCategoria = agrupado;
      _totalGeral = total;
      _carregando = false;
    });
  }

  String _formatarData(DateTime data) =>
      DateFormat('yyyy-MM-dd').format(data);

  Future<void> _selecionarDataInicial() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dataInicial = picked);
      _carregarRelatorio();
    }
  }

  Future<void> _selecionarDataFinal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataFinal,
      firstDate: _dataInicial,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dataFinal = picked);
      _carregarRelatorio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de Despesas'),
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _selecionarDataInicial,
                  child: Text('Início: ${DateFormat('dd/MM/yyyy').format(_dataInicial)}'),
                ),
                TextButton(
                  onPressed: _selecionarDataFinal,
                  child: Text('Fim: ${DateFormat('dd/MM/yyyy').format(_dataFinal)}'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _totaisPorCategoria.entries.map((entry) {
                  final categoria = entry.key;
                  final subcategorias = entry.value;
                  return ExpansionTile(
                    title: Text(categoria, style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      ...subcategorias.entries.map((sub) {
                        return ListTile(
                          title: Text(sub.key),
                          trailing: Text(
                            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                                .format(sub.value),
                          ),
                        );
                      }),
                      Divider(),
                      ListTile(
                        title: Text(
                          'Subtotal $categoria',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(
                            subcategorias.values.fold(0.0, (soma, valor) => soma + valor),
                          ),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            Divider(),
            Text(
              'Total Geral: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_totalGeral)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
