import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/app_providers.dart';

class TelaVerificacaoEmail extends ConsumerStatefulWidget {
  const TelaVerificacaoEmail({super.key});

  @override
  ConsumerState<TelaVerificacaoEmail> createState() =>
      _TelaVerificacaoEmailState();
}

class _TelaVerificacaoEmailState extends ConsumerState<TelaVerificacaoEmail> {
  final List<TextEditingController> _ctrls =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(8, (_) => FocusNode());
  bool _reenviando = false;
  bool _reenviadoOk = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _codigo => _ctrls.map((c) => c.text).join();

  Future<void> _verificar() async {
    final code = _codigo;
    if (code.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Digite todos os 8 dígitos.',
            style: GoogleFonts.interTight(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    final email = ModalRoute.of(context)!.settings.arguments as String;
    final ok = await ref.read(authProvider.notifier).verificarOTP(email, code);
    if (!ok || !mounted) return;

    final usuarioId = ref.read(authProvider).usuarioId!;
    await ref.read(contaProvider.notifier).carregar(usuarioId);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.app);
  }

  Future<void> _reenviar() async {
    if (_reenviando) return;
    final email = ModalRoute.of(context)!.settings.arguments as String;
    setState(() {
      _reenviando = true;
      _reenviadoOk = false;
    });
    await ref.read(authProvider.notifier).reenviarCodigo(email);
    if (!mounted) return;
    setState(() {
      _reenviando = false;
      _reenviadoOk = true;
    });
    // Clear boxes
    for (final c in _ctrls) {
      c.clear();
    }
    _nodes.first.requestFocus();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 7) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
        _verificar();
      }
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      _ctrls[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final auth = ref.watch(authProvider);
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Verifique seu e-mail',
                  style: GoogleFonts.interTight(
                    color: textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  'Enviamos um código de 6 dígitos para',
                  style: GoogleFonts.interTight(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.interTight(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // OTP boxes
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          8,
                          (i) => _DigitBox(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            isDark: isDark,
                            onChanged: (v) => _onDigitChanged(i, v),
                            onKeyEvent: (e) => _onKeyDown(i, e),
                          ),
                        ),
                      ),

                      // Error
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.expense,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: GoogleFonts.interTight(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.gradientPrimary,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _verificar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Verificar código',
                                    style: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Resend
                if (_reenviadoOk)
                  Text(
                    'Novo código enviado! Verifique sua caixa de entrada.',
                    style: GoogleFonts.interTight(
                      color: AppColors.income,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  TextButton(
                    onPressed: _reenviando ? null : _reenviar,
                    child: Text(
                      _reenviando ? 'Reenviando...' : 'Não recebeu? Reenviar código',
                      style: GoogleFonts.interTight(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Back to login
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Voltar ao login',
                    style: GoogleFonts.interTight(
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _DigitBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: 36,
        height: 48,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.visiblePassword,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            _UpperCaseFormatter(),
          ],
          style: GoogleFonts.interTight(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.primary.withValues(alpha: 0.04),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
