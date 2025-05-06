
class DespesaModel {
  final String id;
  final DateTime data;
  final String categoria;
  final String subcategoria;
  final double valor;
  final String descricao;

  DespesaModel({
    required this.id,
    required this.data,
    required this.categoria,
    required this.subcategoria,
    required this.valor,
    required this.descricao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'categoria': categoria,
      'subcategoria': subcategoria,
      'valor': valor,
      'descricao': descricao,
    };
  }

  factory DespesaModel.fromMap(Map<String, dynamic> map) {
    return DespesaModel(
      id: map['id'],
      data: DateTime.parse(map['data']),
      categoria: map['categoria'],
      subcategoria: map['subcategoria'],
      valor: (map['valor'] as num).toDouble(),
      descricao: map['descricao'],
    );
  }
}
