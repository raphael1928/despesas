
import '../models/despesa_model.dart';

abstract class DespesaRepository {
  Future<void> salvarDespesa(DespesaModel despesa);
  Future<void> atualizarDespesa(DespesaModel despesa);
  Future<void> excluirDespesa(String id);
  Future<List<DespesaModel>> buscarDespesasPorData(DateTime data, String usuario);
}
