import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../gerenciadores/login_gerenciador.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> with TickerProviderStateMixin {
  static const _azul = Color(0xFF0D47A1);
  static const _azulClaro = Color(0xFF2979FF);
  static const _fundo = Color(0xFFF3F7FE);
  static const _texto = Color(0xFF10243E);
  static const _textoSuave = Color(0xFF6B7A90);

  late final AnimationController _entradaCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));
    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Consumer<LoginGerenciador>(
                builder: (context, loginVM, _) {
                  return FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBrandHeader(),
                          const SizedBox(height: 18),
                          _buildFormCard(context, loginVM),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_azul, Color(0xFF1565C0), _azulClaro],
        ),
        boxShadow: [
          BoxShadow(
            color: _azul.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: 18,
            child: Transform.rotate(
              angle: -0.45,
              child: Container(
                width: 190,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: _azul,
                  size: 30,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'AquiBank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Controle entradas, despesas e relatórios em uma experiência simples.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, LoginGerenciador loginVM) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5ECF7)),
        boxShadow: [
          BoxShadow(
            color: _azul.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Column(
              key: ValueKey(loginVM.modoLogin),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loginVM.modoLogin ? 'Bem-vindo de volta' : 'Crie sua conta',
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loginVM.modoLogin
                      ? 'Entre para acessar sua dashboard.'
                      : 'Cadastre seus dados para começar.',
                  style: const TextStyle(
                    color: _textoSuave,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Column(
              children: [
                if (!loginVM.modoLogin) ...[
                  _CampoTexto(
                    controlador: loginVM.campoNome,
                    rotulo: 'Nome completo',
                    icone: Icons.person_rounded,
                    acao: TextInputAction.next,
                    capitalizacao: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          _CampoTexto(
            controlador: loginVM.campoEmail,
            rotulo: 'E-mail',
            icone: Icons.mail_rounded,
            tipoTeclado: TextInputType.emailAddress,
            acao: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _CampoTexto(
            controlador: loginVM.campoSenha,
            rotulo: 'Senha',
            icone: Icons.lock_rounded,
            oculto: true,
            acao: TextInputAction.done,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: loginVM.mensagemErro == null
                ? const SizedBox(height: 20)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFE53935),
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loginVM.mensagemErro!,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_azul, Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _azul.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (loginVM.validarEEntrar()) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text(loginVM.modoLogin ? 'Entrar' : 'Criar conta'),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: loginVM.alternarModo,
            style: TextButton.styleFrom(
              foregroundColor: _azul,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: Text(
              loginVM.modoLogin
                  ? 'Criar uma nova conta'
                  : 'Já tenho uma conta',
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String rotulo;
  final IconData icone;
  final bool oculto;
  final TextInputType? tipoTeclado;
  final TextInputAction? acao;
  final TextCapitalization capitalizacao;

  const _CampoTexto({
    required this.controlador,
    required this.rotulo,
    required this.icone,
    this.oculto = false,
    this.tipoTeclado,
    this.acao,
    this.capitalizacao = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      obscureText: oculto,
      keyboardType: tipoTeclado,
      textInputAction: acao,
      textCapitalization: capitalizacao,
      style: const TextStyle(
        color: _TelaLoginState._texto,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: rotulo,
        labelStyle: const TextStyle(
          color: _TelaLoginState._textoSuave,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icone, color: _TelaLoginState._azul),
        filled: true,
        fillColor: const Color(0xFFF6F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2EAF7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2EAF7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _TelaLoginState._azul, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
