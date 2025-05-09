
import '../../data/datasources/reports_datasource.dart';
import '../models/reports_model.dart';

class GerarRelatorioUseCase {
  final RelatorioDatasource datasource;

  GerarRelatorioUseCase(this.datasource);

  Future<List<RelatorioItem>> call(DateTime de, DateTime ate, String usuario) async {
    final despesas = await datasource.buscarDespesasNoPeriodo(de, ate, usuario);
    final Map<String, Map<String, double>> agrupado = {};

    for (var d in despesas) {
      agrupado.putIfAbsent(d.categoria, () => {});
      agrupado[d.categoria]!.update(d.subcategoria, (v) => v + d.valor, ifAbsent: () => d.valor);
    }

    return agrupado.entries.map((entry) {
      final total = entry.value.values.fold(0.0, (a, b) => a + b);
      return RelatorioItem(
        categoria: entry.key,
        subcategorias: entry.value,
        total: total,
      );
    }).toList();
  }
}
