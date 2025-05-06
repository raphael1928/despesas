import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/despesas/presentation/viewmodels/despesa_viewmodel.dart';
import 'features/despesas/domain/usecases/salvar_despesa_usecase.dart';
import 'features/despesas/data/repositories/despesa_repository_impl.dart';
import 'features/despesas/data/datasources/firebase_despesa_datasource.dart';
import 'features/despesas/presentation/views/despesas_page.dart';
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
