
import '../models/expenses_model.dart';
import '../repositories/expenses_repository.dart';

class SalvarDespesaUseCase {
  final DespesaRepository repository;

  SalvarDespesaUseCase(this.repository);

  Future<void> call(DespesaModel despesa) {
    return repository.salvarDespesa(despesa);
  }
}
