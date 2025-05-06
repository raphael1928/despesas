
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../despesas/domain/models/despesa_model.dart';

class RelatorioDatasource {
  final FirebaseFirestore firestore;

  RelatorioDatasource(this.firestore);

  Future<List<DespesaModel>> buscarDespesasNoPeriodo(DateTime de, DateTime ate, String usuario) async {
    final snapshot = await firestore
        .collection('users')
        .doc(usuario)
        .collection('despesas')
        .where('data', isGreaterThanOrEqualTo: de.toIso8601String())
        .where('data', isLessThanOrEqualTo: ate.toIso8601String())
        .get();

    return snapshot.docs.map((doc) => DespesaModel.fromMap(doc.data())).toList();
  }
}
