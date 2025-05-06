
import '../models/despesa_model.dart';
import '../repositories/despesa_repository.dart';

class SalvarDespesaUseCase {
  final DespesaRepository repository;

  SalvarDespesaUseCase(this.repository);

  Future<void> call(DespesaModel despesa) {
    return repository.salvarDespesa(despesa);
  }
}
