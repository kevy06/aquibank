import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gerenciadores/login_gerenciador.dart';
import 'gerenciadores/conta_gerenciador.dart';
import 'telas/tela_login.dart';
import 'telas/tela_home.dart';
import 'telas/tela_relatorio.dart';

void main() {
  runApp(const AquiBankApp());
}

class AquiBankApp extends StatelessWidget {
  const AquiBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginGerenciador()),
        ChangeNotifierProvider(create: (_) => ContaGerenciador()),
      ],
      child: MaterialApp(
        title: 'AquiBank',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0D47A1),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF0F4FA),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const TelaLogin(),
          '/home': (context) => const TelaHome(),
          '/relatorio': (context) => const TelaRelatorio(),
        },
      ),
    );
  }
}
