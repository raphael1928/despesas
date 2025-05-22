import 'package:brasil_fields/brasil_fields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/recurring_expenses.dart';

class RecurringExpensesCard extends StatefulWidget {
  final RecurringExpenses recurringExpenses;
  final String usuario;

  const RecurringExpensesCard({
    super.key,
    required this.recurringExpenses,
    required this.usuario,
  });

  @override
  State<RecurringExpensesCard> createState() => _RecurringExpensesCardState();
}

class _RecurringExpensesCardState extends State<RecurringExpensesCard> {
  late Future<Map<String, dynamic>> _pagamentoInfo;

  @override
  void initState() {
    super.initState();
    _pagamentoInfo = _verificarPagamento();
  }

  Future<Map<String, dynamic>> _verificarPagamento() async {
    final agora = DateTime.now();

    final pagamentos = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas_recorrentes')
        .doc(widget.recurringExpenses.id)
        .collection('pagamentos')
        .orderBy('dataPagamento')
        .get();

    final totalPagos = pagamentos.docs.length;
    final totalParcelas = widget.recurringExpenses.parcelasTotais;

    if (totalParcelas != null && totalPagos >= totalParcelas) {
      return {'concluido': true}; // Oculta da lista
    }

    final isPagoEsteMes = pagamentos.docs.any((doc) {
      final data = DateTime.tryParse(doc['dataPagamento']);
      return data != null &&
          data.month == agora.month &&
          data.year == agora.year;
    });

    return {
      'isPago': isPagoEsteMes,
      'totalPagos': totalPagos,
      'concluido': false,
    };
  }

  Future<void> registrarPagamento() async {
    final controller = TextEditingController(
      text: widget.recurringExpenses.valor.toStringAsFixed(2).replaceAll('.', ','),
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Informe o valor pago de "${widget.recurringExpenses.name}":'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CentavosInputFormatter(moeda: true),
              ],
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final valorPago = UtilBrasilFields.converterMoedaParaDouble(controller.text);

    if (valorPago <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Valor inválido')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas_recorrentes')
        .doc(widget.recurringExpenses.id)
        .collection('pagamentos')
        .add({
      'dataPagamento': DateTime.now().toIso8601String(),
      'valorPago': valorPago,
    });

    setState(() {
      _pagamentoInfo = _verificarPagamento();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pagamento registrado com sucesso')),
    );
  }

  Future<void> removerPagamento() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover Pagamento'),
        content: Text('Deseja remover o pagamento de "${widget.recurringExpenses.name}" deste mês?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final agora = DateTime.now();

    final pagamentosRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas_recorrentes')
        .doc(widget.recurringExpenses.id)
        .collection('pagamentos');

    final pagamentos = await pagamentosRef.get();

    for (final doc in pagamentos.docs) {
      final data = DateTime.tryParse(doc['dataPagamento']);
      if (data != null && data.month == agora.month && data.year == agora.year) {
        await pagamentosRef.doc(doc.id).delete();
      }
    }

    setState(() {
      _pagamentoInfo = _verificarPagamento();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pagamento removido com sucesso')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final dataAssinatura = widget.recurringExpenses.isActive
        ? dateFormat.format(widget.recurringExpenses.signUpDate)
        : '--/--/----';

    final valorFormatado = currencyFormat.format(widget.recurringExpenses.valor);

    return FutureBuilder<Map<String, dynamic>>(
      future: _pagamentoInfo,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        final info = snapshot.data!;
        if (info['concluido'] == true) return SizedBox.shrink();

        final isPago = info['isPago'] ?? false;
        final totalPagos = info['totalPagos'] ?? 0;
        final totalParcelas = widget.recurringExpenses.parcelasTotais;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.recurringExpenses.iconPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recurringExpenses.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Data de Vencimento  $dataAssinatura'),
                    Text('Valor: $valorFormatado'),
                    if (totalParcelas != null)
                      Text('Parcela: ${totalPagos + 1}/$totalParcelas'),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isPago ? Icons.check_circle : Icons.cancel,
                  color: isPago ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  if (isPago) {
                    removerPagamento();
                  } else {
                    registrarPagamento();
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }
}
