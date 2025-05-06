
import 'package:flutter/material.dart';
import '../../domain/models/relatorio_model.dart';
import '../../domain/usecases/gerar_relatorio_usecase.dart';

class RelatorioViewModel extends ChangeNotifier {
  final GerarRelatorioUseCase gerarRelatorioUseCase;
  List<RelatorioItem> relatorio = [];
  bool carregando = false;

  RelatorioViewModel(this.gerarRelatorioUseCase);

  Future<void> gerarRelatorio(DateTime de, DateTime ate, String usuario) async {
    carregando = true;
    notifyListeners();

    relatorio = await gerarRelatorioUseCase(de, ate, usuario);

    carregando = false;
    notifyListeners();
  }
}
