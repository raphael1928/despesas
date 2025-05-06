
sealed class DespesaIntent {}

class CarregarDespesasIntent extends DespesaIntent {
  final DateTime data;
  CarregarDespesasIntent(this.data);
}

class AdicionarDespesaIntent extends DespesaIntent {}

class EditarDespesaIntent extends DespesaIntent {
  final String id;
  EditarDespesaIntent(this.id);
}

class SalvarDespesaIntent extends DespesaIntent {}

class ExcluirDespesaIntent extends DespesaIntent {
  final String id;
  ExcluirDespesaIntent(this.id);
}
