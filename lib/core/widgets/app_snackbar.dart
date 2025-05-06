
import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
