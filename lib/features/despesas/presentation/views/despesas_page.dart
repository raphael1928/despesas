import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import '../../../relatorios/presentation/views/relatorio_page.dart';

class DespesasPage extends StatefulWidget {
  final String usuario;
  const DespesasPage({required this.usuario, Key? key}) : super(key: key);

  @override
  State<DespesasPage> createState() => _DespesasPageState();
}

class _DespesasPageState extends State<DespesasPage> {
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  String? _categoriaSelecionada;
  String? _subcategoriaSelecionada;
  DateTime _dataSelecionada = DateTime.now();
  String? _documentoEmEdicao;

  Map<String, List<String>> _categoriasMap = {};
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _despesasDoDia = [];

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    _carregarDespesas();
  }

  Future<void> _carregarCategorias() async {
    final snapshot = await FirebaseFirestore.instance.collection('categorias').get();

    Map<String, List<String>> map = {};
    for (var doc in snapshot.docs) {
      map[doc.id] = List<String>.from(doc['subcategorias']);
    }

    setState(() {
      _categoriasMap = map;
    });
  }

  Future<void> _carregarDespesas() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas')
        .orderBy('data', descending: true)
        .get();

    setState(() {
      _despesasDoDia = snapshot.docs.where((doc) {
        final data = DateTime.tryParse(doc['data']);
        if (data == null) return false;
        return data.year == _dataSelecionada.year &&
            data.month == _dataSelecionada.month &&
            data.day == _dataSelecionada.day;
      }).toList();
    });
  }

  Future<void> _salvarOuAtualizar() async {
    if (_categoriaSelecionada == null ||
        _subcategoriaSelecionada == null ||
        _valorController.text.isEmpty ||
        (_categoriaSelecionada == 'Outros' &&
            _descricaoController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    final valor = UtilBrasilFields.converterMoedaParaDouble(_valorController.text);
    final data = DateFormat('yyyy-MM-dd').format(_dataSelecionada);

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas');

    if (_documentoEmEdicao != null) {
      await ref.doc(_documentoEmEdicao).update({
        'categoria': _categoriaSelecionada,
        'subcategoria': _subcategoriaSelecionada,
        'valor': valor,
        'descricao': _descricaoController.text,
        'data': data,
      });
    } else {
      await ref.add({
        'categoria': _categoriaSelecionada,
        'subcategoria': _subcategoriaSelecionada,
        'valor': valor,
        'descricao': _descricaoController.text,
        'data': data,
      });
    }

    _limparCampos();
    _carregarDespesas();
  }

  void _limparCampos() {
    _valorController.clear();
    _descricaoController.clear();
    _categoriaSelecionada = null;
    _subcategoriaSelecionada = null;
    _documentoEmEdicao = null;
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() => _dataSelecionada = data);
      _carregarDespesas();
    }
  }

  Future<void> _confirmarExclusao(String docId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Excluir Despesa'),
          content: Text('Tem certeza que deseja excluir esta despesa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Sim'),
            ),
          ],
        );
      },
    );

    // Cancelar se o widget foi desmontado ou se o usuário cancelou
    if (!mounted || confirmar != true) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas')
        .doc(docId)
        .delete();

    if (mounted) _carregarDespesas();
  }

  void _preencherParaEdicao(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final dados = doc.data();
    setState(() {
      _categoriaSelecionada = dados['categoria'];
      _subcategoriaSelecionada = dados['subcategoria'];
      _valorController.text = dados['valor'].toStringAsFixed(2).replaceAll('.', ',');
      _descricaoController.text = dados['descricao'] ?? '';
      _documentoEmEdicao = doc.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(_dataSelecionada);

    return Scaffold(
      appBar: AppBar(
        title: Text('Controle de Despesas'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarDespesas,
          ),
          IconButton(
            icon: Icon(Icons.insert_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RelatorioPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Data: $dataFormatada'),
          ElevatedButton(
            onPressed: _selecionarData,
            child: Text('Selecionar Data'),
          ),
          SizedBox(height: 10),
          DropdownButton<String>(
            isExpanded: true,
            hint: Text('Categoria'),
            value: _categoriaSelecionada,
            items: _categoriasMap.keys.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
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
            isExpanded: true,
            hint: Text('Subcategoria'),
            value: _subcategoriaSelecionada,
            items: (_categoriasMap[_categoriaSelecionada] ?? [])
                .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                .toList(),
            onChanged: (value) => setState(() => _subcategoriaSelecionada = value),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _valorController,
            decoration: InputDecoration(labelText: 'Valor (R\$)'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CentavosInputFormatter(moeda: true),
            ],
          ),
          SizedBox(height: 10),
          TextField(
            controller: _descricaoController,
            decoration: InputDecoration(
              labelText: 'Descrição (obrigatória se "Outros")',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _salvarOuAtualizar,
            child: Text(_documentoEmEdicao != null ? 'Salvar Alteração' : 'Adicionar Despesa'),
          ),
          SizedBox(height: 20),
          Divider(),
          Text(
            'Despesas do dia:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._despesasDoDia.map((doc) {
            final data = doc.data();
            return ListTile(
              title: Text('${data['categoria']} - ${data['subcategoria']}'),
              subtitle: data['descricao'] != null && data['descricao'].toString().isNotEmpty
                  ? Text(data['descricao'])
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('R\$ ${data['valor'].toStringAsFixed(2)}'),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _preencherParaEdicao(doc),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarExclusao(doc.id),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
