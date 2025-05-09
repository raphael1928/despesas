
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../domain/usecases/generate_report_usecase.dart';
import '../../data/datasources/reports_datasource.dart';
import '../viewmodels/reports_viewmodel.dart';
import 'reports_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RelatorioLauncherPage extends StatefulWidget {
  final String usuario;

  const RelatorioLauncherPage({required this.usuario, super.key});

  @override
  State<RelatorioLauncherPage> createState() => _RelatorioLauncherPageState();
}

class _RelatorioLauncherPageState extends State<RelatorioLauncherPage> {
  late DateTime _inicio;
  late DateTime _fim;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _fim = hoje;
    _inicio = hoje.subtract(Duration(days: 7));
  }

  void _selecionarIntervalo() async {
    final intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _inicio, end: _fim),
    );

    if (intervalo != null) {
      setState(() {
        _inicio = intervalo.start;
        _fim = intervalo.end;
      });
    }
  }

  void _abrirRelatorio() {
    final firestore = FirebaseFirestore.instance;
    final datasource = RelatorioDatasource(firestore);
    final usecase = GerarRelatorioUseCase(datasource);
    final viewModel = RelatorioViewModel(usecase);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              LoadingOverlay.show(context);
              await Provider.of<RelatorioViewModel>(context, listen: false)
                  .gerarRelatorio(_inicio, _fim, widget.usuario);
            });
            LoadingOverlay.hide(context);
            AppSnackbar.show(context, 'Relatório gerado com sucesso!');
            return RelatorioPage();
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Relatório de Despesas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Período: ${_inicio.toLocal().toString().split(' ')[0]} até ${_fim.toLocal().toString().split(' ')[0]}'),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.calendar_month),
              label: Text('Selecionar intervalo'),
              onPressed: _selecionarIntervalo,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.bar_chart),
              label: Text('Gerar Relatório'),
              onPressed: _abrirRelatorio,
            )
          ],
        ),
      ),
    );
  }
}
