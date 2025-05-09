import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // para usar DateUtils.getDaysInMonth

class Subscription {
  final String id;
  final String name;
  final DateTime signUpDate;
  final bool isActive;

  Subscription({
    required this.id,
    required this.name,
    required this.signUpDate,
    required this.isActive,
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
    if (lower.contains('netflix')) return 'assets/icons/netflix.svg';
    if (lower.contains('disney')) return 'assets/icons/disney.svg';
    if (lower.contains('prime')) return 'assets/icons/prime.svg';
    if (lower.contains('youtube')) return 'assets/icons/youtube.svg';
    if (lower.contains('hbo') || lower.contains('max')) return 'assets/icons/hbo_max.svg';
    if (lower.contains('chatgpt')) return 'assets/icons/chatgpt.svg';
    if (lower.contains('ifood')) return 'assets/icons/ifood.svg';
    if (lower.contains('linkedin')) return 'assets/icons/linkedin.svg';
    return 'assets/icons/default.svg';
  }

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['tipo'] ?? '';
    final date = DateTime.parse(data['dataAssinatura']);
    return Subscription(
      id: doc.id,
      name: name,
      signUpDate: date,
      isActive: data['ativo'] ?? true,
    );
  }
}
