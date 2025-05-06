
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static Future<void> salvarNomeUsuario(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nomeUsuario', nome);
  }

  static Future<String?> obterNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nomeUsuario');
  }
}
