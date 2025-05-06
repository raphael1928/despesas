
class RelatorioItem {
  final String categoria;
  final Map<String, double> subcategorias; // subcategoria: valor
  final double total;

  RelatorioItem({
    required this.categoria,
    required this.subcategorias,
    required this.total,
  });
}
