
import 'package:flutter/material.dart';
import '../../domain/models/despesa_model.dart';
import '../../domain/usecases/salvar_despesa_usecase.dart';

class DespesaViewModel extends ChangeNotifier {
  final SalvarDespesaUseCase salvarDespesaUseCase;

  DespesaViewModel(this.salvarDespesaUseCase);

  List<DespesaModel> despesas = [];

  Future<void> salvarDespesa(DespesaModel despesa) async {
    await salvarDespesaUseCase(despesa);
    despesas.add(despesa);
    notifyListeners();
  }

  void limparDespesas() {
    despesas.clear();
    notifyListeners();
  }
}
