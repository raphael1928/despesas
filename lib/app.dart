import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/expenses/presentation/viewmodels/expense_viewmodel.dart';
import 'features/expenses/domain/usecases/save_expense_usecase.dart';
import 'features/expenses/data/repositories/expenses_repository_impl.dart';
import 'features/expenses/data/datasources/firebase_expenses_datasource.dart';
import 'features/expenses/presentation/views/expenses_page.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  final String usuario;

  const MyApp({required this.usuario, super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final datasource = FirebaseDespesaDatasource(firestore);
    final repository = DespesaRepositoryImpl(
      datasource: datasource,
      usuario: usuario,
    );
    final salvarUseCase = SalvarDespesaUseCase(repository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DespesaViewModel(salvarUseCase),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Despesas App',
        theme: AppTheme.light,
        home: DespesasPage(usuario: usuario),
      ),
    );
  }
}
