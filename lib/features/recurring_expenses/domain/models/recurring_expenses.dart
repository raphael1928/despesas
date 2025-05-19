import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Necessário para DateUtils.getDaysInMonth

class RecurringExpenses {
  final String id;
  final String name;
  final DateTime signUpDate;
  final bool isActive;
  final double valor;
  final bool isPaid;
  final DateTime? dataPagamento;

  RecurringExpenses({
    required this.id,
    required this.name,
    required this.signUpDate,
    required this.isActive,
    required this.valor,
    required this.isPaid,
    required this.dataPagamento,
  });

  // Calcula renovação com base no mês/ano atual e dia da assinatura
  DateTime get renewalDate {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      signUpDate.day.clamp(1, DateUtils.getDaysInMonth(now.year, now.month)),
    );
  }

  // Retorna caminho do ícone com base no nome
  String get iconPath {
    final lower = name.toLowerCase();

    if (lower.contains('aluguel')) return 'assets/icons/aluguel.png';
    if (lower.contains('energia')) return 'assets/icons/energia.png';
    if (lower.contains('água') || lower.contains('agua')) return 'assets/icons/agua.png';
    if (lower.contains('internet')) return 'assets/icons/internet.png';
    if (lower.contains('telefone')) return 'assets/icons/telefone.png';
    if (lower.contains('dentista')) return 'assets/icons/dentista.png';
    if (lower.contains('beach tennis arena')) return 'assets/icons/beach_arena.png';
    if (lower.contains('beach tennis aulas')) return 'assets/icons/beach_aulas.png';
    if (lower.contains('carro')) return 'assets/icons/carro.png';
    if (lower.contains('lote')) return 'assets/icons/lote.png';
    if (lower.contains('condomínio') || lower.contains('condominio')) return 'assets/icons/condominio.png';
    if (lower.contains('ipva')) return 'assets/icons/ipva.png';

    return 'assets/icons/default.png';
  }

  factory RecurringExpenses.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final name = data['tipo']?.toString() ?? 'Desconhecido';
    final dateRaw = data['dataVencimento'];
    final valor = (data['valor'] as num?)?.toDouble() ?? 0.0;
    final isPaid = data['pago'] ?? false;
    final dataPagamento = data['dataPagamento'] != null
        ? DateTime.tryParse(data['dataPagamento']) ?? null
        : null;

    DateTime date;
    if (dateRaw is String) {
      date = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else if (dateRaw is Timestamp) {
      date = dateRaw.toDate();
    } else {
      date = DateTime.now();
    }

    return RecurringExpenses(
      id: doc.id,
      name: name,
      signUpDate: date,
      isActive: data['ativo'] ?? true,
      valor: valor,
      isPaid: isPaid,
      dataPagamento: dataPagamento
    );
  }
}
