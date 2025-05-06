
import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double valor) {
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return formatter.format(valor);
  }

  static String formatDate(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  static String formatDateTime(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }
}
