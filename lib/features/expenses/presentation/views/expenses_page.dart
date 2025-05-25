import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../pages/coletar_nome_page.dart';
import '../../../assets/presentation/views/assets_page.dart';
import '../../../emergency_reserve/presentation/views/emergency_reserve_page.dart';
import '../../../expense_limit/presentation/views/expense_limit_page.dart';
import '../../../goals/presentation/views/goals_page.dart';
import '../../../recurring_expenses/presentation/views/recurring_expenses_page.dart';
import '../../../reports/presentation/views/reports_page.dart';
import 'package:flu/features/subscriptions/presentation/views/subscriptions_page.dart';

extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

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
  double _totalDoDia = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    _carregarDespesas();
  }

  Future<void> _carregarCategorias() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categorias').get();

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

    final docsFiltrados = snapshot.docs.where((doc) {
      final data = DateTime.tryParse(doc['data']);
      return data != null &&
          data.year == _dataSelecionada.year &&
          data.month == _dataSelecionada.month &&
          data.day == _dataSelecionada.day;
    }).toList();

    final total = docsFiltrados.fold<double>(
      0.0,
          (soma, doc) => soma + (doc['valor'] as num).toDouble(),
    );

    setState(() {
      _despesasDoDia = docsFiltrados;
      _totalDoDia = total;
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

    final valor = UtilBrasilFields.converterMoedaParaDouble(
      _valorController.text,
    );
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
      _valorController.text = dados['valor']
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _descricaoController.text = dados['descricao'] ?? '';
      _documentoEmEdicao = doc.id;
    });
  }

  Future<void> _alterarDataDespesa(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final dataAtual = DateTime.tryParse(doc['data']) ?? DateTime.now();

    final novaData = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (novaData == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Confirmar alteração'),
            content: Text(
              'Deseja alterar a data da despesa para ${DateFormat('dd/MM/yyyy').format(novaData)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Sim'),
              ),
            ],
          ),
    );

    if (confirmado == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.usuario)
          .collection('despesas')
          .doc(doc.id)
          .update({'data': novaData.toIso8601String()});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Data atualizada com sucesso.')));
      _carregarDespesas(); // ou recarregue como preferir
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(_dataSelecionada);

    return Scaffold(
      appBar: AppBar(
        title: Text('Despesas - ${widget.usuario}'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _carregarDespesas),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.stream),
              title: Text('Assinaturas'),
              onTap: () {
                Navigator.pop(context); // fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SubscriptionsPage(usuario: widget.usuario)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cached),
              title: Text('Despesas Recorrentes'),
              onTap: () {
                Navigator.pop(context); // fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecurringExpensesPage(usuario: widget.usuario),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.pie_chart),
              title: Text('Limite de Despesas'),
              onTap: () {
                Navigator.pop(context); // fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseLimitPage(usuario: widget.usuario),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.savings),
              title: Text('Objetivos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoalsPage(usuario: widget.usuario),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.account_balance),
              title: Text('Patrimônio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssetsPage(usuario: widget.usuario),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Reserva de Emergência'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmergencyReservePage(usuario: widget.usuario),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('nomeUsuario');

                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => ColetarNomePage()),
                      (route) => false,
                );
              },
            ),

          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _selecionarData,
            child: Text(
              '${DateFormat('dd/MM/yyyy').format(_dataSelecionada)} - ${DateFormat('EEEE', 'pt_BR').format(_dataSelecionada).capitalize()}',
            ),
          ),
          SizedBox(height: 10),
          DropdownButton<String>(
            isExpanded: true,
            hint: Text('Categoria'),
            value: _categoriaSelecionada,
            items:
                _categoriasMap.keys.map((cat) {
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
            items:
                (_categoriasMap[_categoriaSelecionada] ?? [])
                    .map(
                      (sub) => DropdownMenuItem(value: sub, child: Text(sub)),
                    )
                    .toList(),
            onChanged:
                (value) => setState(() => _subcategoriaSelecionada = value),
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
            decoration: InputDecoration(labelText: 'Descrição'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _salvarOuAtualizar,
            child: Text(
              _documentoEmEdicao != null
                  ? 'Salvar Alteração'
                  : 'Adicionar Despesa',
            ),
          ),
          SizedBox(height: 20),
          Divider(),
          Text(
            'Despesas do dia:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._despesasDoDia.map((doc) {
            final data = doc.data();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2.0,
                    vertical: 2.0,
                  ), // margem bem reduzida
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['categoria']} - ${data['subcategoria']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'R\$ ${data['valor'].toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.blue),
                        onPressed: () => _alterarDataDespesa(context, doc),
                      ),
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
                ),
                Divider(height: 1, color: Colors.grey.shade300),
              ],
            );
          }).toList(),
          SizedBox(height: 12),
          Text(
            'Total do dia: R\$ ${_totalDoDia.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
