import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  late Future<bool> _isPagoEsteMes;

  @override
  void initState() {
    super.initState();
    _isPagoEsteMes = verificarSePagoEsteMes();
  }

  Future<bool> verificarSePagoEsteMes() async {
    final agora = DateTime.now();

    final pagamentos = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas_recorrentes')
        .doc(widget.recurringExpenses.id)
        .collection('pagamentos')
        .get();

    return pagamentos.docs.any((doc) {
      final data = DateTime.tryParse(doc['dataPagamento']);
      return data != null &&
          data.month == agora.month &&
          data.year == agora.year;
    });
  }

  Future<void> registrarPagamento() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar Pagamento'),
        content: Text('Deseja registrar o pagamento de "${widget.recurringExpenses.name}" neste mês?'),
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

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.usuario)
        .collection('despesas_recorrentes')
        .doc(widget.recurringExpenses.id)
        .collection('pagamentos')
        .add({
      'dataPagamento': DateTime.now().toIso8601String(),
      'valorPago': widget.recurringExpenses.valor,
    });

    setState(() {
      _isPagoEsteMes = verificarSePagoEsteMes(); // força rebuild com o novo estado
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pagamento registrado com sucesso')),
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
              ],
            ),
          ),
          FutureBuilder<bool>(
            future: _isPagoEsteMes,
            builder: (context, snapshot) {
              final isPago = snapshot.data ?? false;

              return IconButton(
                icon: Icon(
                  isPago ? Icons.check_circle : Icons.cancel,
                  color: isPago ? Colors.green : Colors.red,
                ),
                onPressed: isPago ? null : registrarPagamento,
              );
            },
          )
        ],
      ),
    );
  }
}
