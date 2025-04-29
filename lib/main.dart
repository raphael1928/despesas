import 'package:flutter/material.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'relatorio_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(DespesasApp());
}

class DespesasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle de Despesas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UsuarioChecker(),
    );
  }
}

class UsuarioChecker extends StatefulWidget {
  @override
  _UsuarioCheckerState createState() => _UsuarioCheckerState();
}

class _UsuarioCheckerState extends State<UsuarioChecker> {
  String? _usuario;

  @override
  void initState() {
    super.initState();
    _verificarUsuario();
  }

  Future<void> _verificarUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nomeUsuario = prefs.getString('nomeUsuario');
    if (nomeUsuario == null) {
      _solicitarNomeUsuario();
    } else {
      setState(() {
        _usuario = nomeUsuario;
      });
    }
  }
  void _solicitarNomeUsuario() {
    final _nomeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Digite seu nome de usuário'),
          content: TextField(
            controller: _nomeController,
            decoration: InputDecoration(hintText: 'Nome de usuário'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String nome = _nomeController.text.trim();
                if (nome.isEmpty) return;
                var doc = await FirebaseFirestore.instance.collection('users').doc(nome).get();
                if (doc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nome já existe, escolha outro.')));
                } else {
                  await FirebaseFirestore.instance.collection('users').doc(nome).set({'criadoEm': DateTime.now().toIso8601String()});
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('nomeUsuario', nome);
                  setState(() {
                    _usuario = nome;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return DespesasPage(nomeUsuario: _usuario!);
    }
  }
}

class DespesasPage extends StatefulWidget {
  final String nomeUsuario;
  DespesasPage({required this.nomeUsuario});

  @override
  _DespesasPageState createState() => _DespesasPageState();
}

class _DespesasPageState extends State<DespesasPage> {
  final _valorController = MoneyMaskedTextController(
    leftSymbol: 'R\$ ',
    decimalSeparator: ',',
    thousandSeparator: '.',
  );

  final _descricaoController = TextEditingController();
  DateTime _dataSelecionada = DateTime.now();

  String? _categoriaSelecionada;
  String? _subcategoriaSelecionada;
  String? _idEmEdicao;

  List<String> _categorias = [];
  Map<String, List<String>> _subcategorias = {};

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    final snapshot = await FirebaseFirestore.instance.collection('categorias').get();

    final categoriasTemp = <String>[];
    final subcategoriasTemp = <String, List<String>>{};

    for (var doc in snapshot.docs) {
      categoriasTemp.add(doc.id);
      subcategoriasTemp[doc.id] = List<String>.from(doc['subcategorias']);
    }

    setState(() {
      _categorias = categoriasTemp;
      _subcategorias = subcategoriasTemp;
    });
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  void _salvarOuAtualizarDespesa() {
    if (_categoriaSelecionada != null &&
        _subcategoriaSelecionada != null &&
        _valorController.numberValue > 0) {
      final dadosDespesa = {
        'data': _dataSelecionada.toIso8601String(),
        'categoria': _categoriaSelecionada!,
        'subcategoria': _subcategoriaSelecionada!,
        'valor': _valorController.numberValue,
        'descricao': _descricaoController.text,
      };

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.nomeUsuario)
          .collection('despesas');

      if (_idEmEdicao == null) {
        ref.add(dadosDespesa);
      } else {
        ref.doc(_idEmEdicao).update(dadosDespesa);
      }

      _limparCampos();
    }
  }

  void _limparCampos() {
    setState(() {
      _valorController.updateValue(0);
      _descricaoController.clear();
      _categoriaSelecionada = null;
      _subcategoriaSelecionada = null;
      _idEmEdicao = null;
    });
  }

  String _formatarTotal(QuerySnapshot snapshot) {
    final total = snapshot.docs.fold(0.0, (soma, doc) {
      final data = DateTime.parse(doc['data']);
      if (DateFormat('dd/MM/yyyy').format(data) == DateFormat('dd/MM/yyyy').format(_dataSelecionada)) {
        return soma + (doc['valor'] as num).toDouble();
      }
      return soma;
    });
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(total);
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.nomeUsuario)
        .collection('despesas');

    return Scaffold(
      appBar: AppBar(
        title: Text('Despesas - ${widget.nomeUsuario}'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics), // Ícone de relatório
            tooltip: 'Relatório',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RelatorioPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    GestureDetector(
    onTap: _selecionarData,
    child: Container(
    padding: EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
    border: Border(bottom: BorderSide(color: Colors.grey)),
    ),
    child: Text(
    'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
    style: TextStyle(fontSize: 16),
    ),
    ),
    ),
    SizedBox(height: 10),
    DropdownButton<String>(
    value: _categoriaSelecionada,
    hint: Text('Selecione a Categoria'),
    isExpanded: true,
    items: _categorias.map((cat) {
    return DropdownMenuItem(
    value: cat,
    child: Text(cat),
    );
    }).toList(),
    onChanged: (value) {
    setState(() {
    _categoriaSelecionada = value;
    _subcategoriaSelecionada = null;
    });
    },
    ),
    SizedBox(height: 10),
    DropdownButton<String>(
    value: _subcategoriaSelecionada,
    hint: Text('Selecione a Subcategoria'),
    isExpanded: true,
    items: (_subcategorias[_categoriaSelecionada] ?? []).map((sub) {
    return DropdownMenuItem(
    value: sub,
    child: Text(sub),
    );
    }).toList(),
    onChanged: (value) {
    setState(() {
    _subcategoriaSelecionada = value;
    });
    },
    ),
    SizedBox(height: 10),
    TextField(
    controller: _valorController,
    decoration: InputDecoration(labelText: 'Valor'),
    keyboardType: TextInputType.number,
    inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    CentavosInputFormatter(),
    ],
    ),
    SizedBox(height: 10),
    TextField(
    controller: _descricaoController,
    decoration: InputDecoration(labelText: 'Descrição'),
    ),
    SizedBox(height: 20),
    ElevatedButton(
    onPressed: _salvarOuAtualizarDespesa,
    child: Text(_idEmEdicao == null ? 'Adicionar Despesa' : 'Salvar Alteração'),
    ),
    SizedBox(height: 20),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: ref.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final despesasFiltradas = snapshot.data!.docs.where((doc) {
              final data = DateTime.parse(doc['data']);
              return DateFormat('dd/MM/yyyy').format(data) ==
                  DateFormat('dd/MM/yyyy').format(_dataSelecionada);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total do Dia: ${_formatarTotal(snapshot.data!)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Divider(),
                despesasFiltradas.isEmpty
                    ? Center(child: Text('Nenhuma despesa para esta data.'))
                    : Expanded(
                  child: ListView.builder(
                    itemCount: despesasFiltradas.length,
                    itemBuilder: (context, index) {
                      final doc = despesasFiltradas[index];
                      return ListTile(
                        title: Text('${doc['categoria']} - ${doc['subcategoria']}'),
                        subtitle: Text(
                          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                              .format((doc['valor'] as num).toDouble()),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                setState(() {
                                  _idEmEdicao = doc.id;
                                  _categoriaSelecionada = doc['categoria'];
                                  _subcategoriaSelecionada = doc['subcategoria'];
                                  _valorController.updateValue((doc['valor'] as num).toDouble());
                                  _descricaoController.text = doc['descricao'];
                                  _dataSelecionada = DateTime.parse(doc['data']);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ref.doc(doc.id).delete();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
    ),
        ),
    );
  }
}
