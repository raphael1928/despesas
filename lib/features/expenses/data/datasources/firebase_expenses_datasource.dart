
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/expenses_model.dart';

class FirebaseDespesaDatasource {
  final FirebaseFirestore firestore;

  FirebaseDespesaDatasource(this.firestore);

  Future<void> salvarDespesa(DespesaModel despesa, String usuario) async {
    await firestore
        .collection('users')
        .doc(usuario)
        .collection('despesas')
        .doc(despesa.id)
        .set(despesa.toMap());
  }

  Future<void> atualizarDespesa(DespesaModel despesa, String usuario) async {
    await firestore
        .collection('users')
        .doc(usuario)
        .collection('despesas')
        .doc(despesa.id)
        .update(despesa.toMap());
  }

  Future<void> excluirDespesa(String id, String usuario) async {
    await firestore
        .collection('users')
        .doc(usuario)
        .collection('despesas')
        .doc(id)
        .delete();
  }

  Future<List<DespesaModel>> buscarDespesasPorData(DateTime data, String usuario) async {
    final inicio = DateTime(data.year, data.month, data.day);
    final fim = inicio.add(Duration(days: 1));

    final snapshot = await firestore
        .collection('users')
        .doc(usuario)
        .collection('despesas')
        .where('data', isGreaterThanOrEqualTo: inicio.toIso8601String())
        .where('data', isLessThanOrEqualTo: fim.toIso8601String())
        .get();

    return snapshot.docs.map((doc) => DespesaModel.fromMap(doc.data())).toList();
  }
}
