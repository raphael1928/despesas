import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flu/features/subscriptions/presentation/views/subscription_form_page.dart';
import 'package:flutter/material.dart';
import '../../domain/models/subscription.dart';
import '../widgets/subscription_card.dart';

class SubscriptionsPage extends StatelessWidget {
  final String usuario;

  const SubscriptionsPage({required this.usuario, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinaturas'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionFormPage(usuario: usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(usuario)
                .collection('assinaturas')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final subscriptions =
              docs.map((doc) => Subscription.fromFirestore(doc)).toList();

          // ordena: ativos primeiro
          subscriptions.sort((a, b) {
            if (a.isActive == b.isActive) return 0;
            return a.isActive ? -1 : 1;
          });

          return ListView.builder(
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SubscriptionFormPage(
                            subscription: subscriptions[index],
                            usuario: usuario,
                          ),
                    ),
                  );
                },
                child: SubscriptionCard(subscription: subscriptions[index]),
              );
            },
          );
        },
      ),

      backgroundColor: const Color(0xFFF6F6F6),
    );
  }
}
