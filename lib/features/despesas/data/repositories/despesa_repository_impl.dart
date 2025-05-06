
import '../../domain/models/despesa_model.dart';
import '../../domain/repositories/despesa_repository.dart';
import '../datasources/firebase_despesa_datasource.dart';

class DespesaRepositoryImpl implements DespesaRepository {
  final FirebaseDespesaDatasource datasource;
  final String usuario;

  DespesaRepositoryImpl({
    required this.datasource,
    required this.usuario,
  });

  @override
  Future<void> salvarDespesa(DespesaModel despesa) {
    return datasource.salvarDespesa(despesa, usuario);
  }

  @override
  Future<void> atualizarDespesa(DespesaModel despesa) {
    return datasource.atualizarDespesa(despesa, usuario);
  }

  @override
  Future<void> excluirDespesa(String id) {
    return datasource.excluirDespesa(id, usuario);
  }

  @override
  Future<List<DespesaModel>> buscarDespesasPorData(DateTime data, String usuario) {
    return datasource.buscarDespesasPorData(data, usuario);
  }
}
