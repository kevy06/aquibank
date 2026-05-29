import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../app/views/main_app.dart';
import '../../cotacoes/views/tela_cotacoes.dart';
import '../../relatorio/views/tela_relatorio.dart';

class TelaPerfil extends ConsumerStatefulWidget {
  const TelaPerfil({super.key});

  @override
  ConsumerState<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends ConsumerState<TelaPerfil> {
  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    await ref.read(fotoPerfilProvider.notifier).definir(picked.path);
  }

  Future<void> _alternarBiometria(BuildContext context, String? usuarioId, bool ativar) async {
    if (usuarioId == null) return;

    final notifier = ref.read(biometriaProvider.notifier);
    if (ativar) {
      final ok = await notifier.ativar(usuarioId);
      if (!mounted) return;
      final erro = ref.read(biometriaProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Login por biometria ativado.' : erro ?? 'Biometria não ativada.'),
          backgroundColor: ok ? AppColors.income : AppColors.expense,
        ),
      );
      return;
    }

    await notifier.desativar(usuarioId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login por biometria desativado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final conta = ref.watch(contaProvider);
    final biometria = ref.watch(biometriaProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(biometriaProvider.notifier).carregar(auth.usuarioId);
    });

    final nome = auth.nomeUsuario ?? 'Usuário';
    final email = auth.emailUsuario ?? '';
    final iniciais = nome.trim().split(' ').take(2).map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
    final totalTransacoes = conta.movimentacoes.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, isDark, nome, email, iniciais, textPrimary, textSecondary),
              const SizedBox(height: 16),
              _buildStats(context, isDark, cardBg, border, textPrimary, textSecondary, conta),
              const SizedBox(height: 20),
              _buildSection(
                context,
                isDark,
                cardBg,
                border,
                textPrimary,
                textSecondary,
                title: 'Aparência',
                children: [
                  _buildThemeToggle(context, ref, isDark, themeMode, textPrimary, textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                isDark,
                cardBg,
                border,
                textPrimary,
                textSecondary,
                title: 'Conta',
                children: [
                  _buildTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.primary,
                    label: 'Nome',
                    trailing: Text(
                      nome,
                      style: GoogleFonts.interTight(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    textPrimary: textPrimary,
                  ),
                  Divider(color: border, height: 1, indent: 52),
                  _buildTile(
                    icon: Icons.mail_outline_rounded,
                    iconColor: AppColors.primaryLight,
                    label: 'E-mail',
                    trailing: Text(
                      email,
                      style: GoogleFonts.interTight(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    textPrimary: textPrimary,
                  ),
                  Divider(color: border, height: 1, indent: 52),
                  _buildTile(
                    icon: Icons.swap_vert_rounded,
                    iconColor: AppColors.income,
                    label: 'Total de transações',
                    trailing: Text(
                      '$totalTransacoes',
                      style: GoogleFonts.interTight(
                        color: textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    textPrimary: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                isDark,
                cardBg,
                border,
                textPrimary,
                textSecondary,
                title: 'Segurança',
                children: [
                  _buildTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.income,
                    label: 'Login por biometria',
                    trailing: Switch.adaptive(
                      value: biometria.isEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.income,
                      onChanged: biometria.isLoading
                          ? null
                          : (v) => _alternarBiometria(context, auth.usuarioId, v),
                    ),
                    textPrimary: textPrimary,
                  ),
                  Divider(color: border, height: 1, indent: 52),
                  _buildTile(
                    icon: Icons.pin_rounded,
                    iconColor: AppColors.primaryLight,
                    label: 'Código PIN',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Em breve', style: GoogleFonts.interTight(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    textPrimary: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                isDark,
                cardBg,
                border,
                textPrimary,
                textSecondary,
                title: 'Geral',
                children: [
                  _buildTile(
                    icon: Icons.language_rounded,
                    iconColor: AppColors.primary,
                    label: 'Idioma',
                    trailing: Text('Português (BR)', style: GoogleFonts.interTight(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                    textPrimary: textPrimary,
                  ),
                  Divider(color: border, height: 1, indent: 52),
                  _buildTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.primaryLight,
                    label: 'Central de Ajuda',
                    onTap: () => _abrirAjuda(context, isDark, textPrimary, textSecondary, border),
                    textPrimary: textPrimary,
                  ),
                  Divider(color: border, height: 1, indent: 52),
                  _buildTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.income,
                    label: 'Sobre o AquiBank',
                    onTap: () => _abrirSobre(context, isDark, textPrimary, textSecondary, border),
                    textPrimary: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                isDark,
                cardBg,
                border,
                textPrimary,
                textSecondary,
                title: 'Legal',
                children: [
                  _buildTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.primary,
                    label: 'Política de Privacidade',
                    onTap: () => _abrirPrivacidade(context, isDark, textPrimary, textSecondary, border),
                    textPrimary: textPrimary,
                  ),
                  Divider(color: border, height: 1, indent: 52),
                  _buildTile(
                    icon: Icons.gavel_rounded,
                    iconColor: AppColors.textSecondaryLight,
                    label: 'Termos de Uso',
                    onTap: () => _abrirTermos(context, isDark, textPrimary, textSecondary, border),
                    textPrimary: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                isDark,
                cardBg,
                border,
                textPrimary,
                textSecondary,
                title: 'Ferramentas',
                children: [
                  _buildTile(
                    icon: Icons.currency_exchange_rounded,
                    iconColor: AppColors.income,
                    label: 'Cotações de câmbio',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCotacoes())),
                    textPrimary: textPrimary,
                  ),
                  Divider(color: border, height: 1, indent: 52),
                  _buildTile(
                    icon: Icons.query_stats_rounded,
                    iconColor: AppColors.primaryLight,
                    label: 'Relatório financeiro',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaRelatorio())),
                    textPrimary: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                isDark,
                cardBg,
                border,
                textPrimary,
                textSecondary,
                title: 'Dados',
                children: [
                  _buildTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.expense,
                    label: 'Limpar todas as transações',
                    onTap: () => _confirmarLimpar(context, ref, isDark, border),
                    textPrimary: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLogoutBtn(context, ref, isDark),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'AquiBank v1.0.0',
                  style: GoogleFonts.interTight(
                    color: textSecondary.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    String nome,
    String email,
    String iniciais,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.gradientPrimary,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Perfil',
                  style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _selecionarFoto,
            child: Stack(
              children: [
                Consumer(
                  builder: (_, ref, __) {
                    final foto = ref.watch(fotoPerfilProvider);
                    return Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                        image: foto != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(foto) as ImageProvider
                                    : FileImage(File(foto)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: foto == null
                          ? Center(
                              child: Text(
                                iniciais.isEmpty ? 'U' : iniciais,
                                style: GoogleFonts.interTight(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color textSecondary,
    ContaState conta,
  ) {
    final now = DateTime.now();
    final entradas = conta.entradasDoMes(now.year, now.month);
    final saidas = conta.saidasDoMes(now.year, now.month);
    final saldo = conta.saldoAtual;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(child: _buildStatItem('Saldo', saldo, saldo >= 0 ? AppColors.income : AppColors.expense, textSecondary)),
            Container(width: 1, height: 44, color: border),
            Expanded(child: _buildStatItem('Entradas', entradas, AppColors.income, textSecondary)),
            Container(width: 1, height: 44, color: border),
            Expanded(child: _buildStatItem('Saídas', saidas, AppColors.expense, textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double valor, Color color, Color textSecondary) {
    final isNegativo = valor < 0;
    final txt = 'R\$ ${valor.abs().toStringAsFixed(2).replaceAll('.', ',')}';
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.interTight(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isNegativo ? '-$txt' : txt,
          style: GoogleFonts.interTight(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color textSecondary, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.interTight(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ThemeMode themeMode,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo escuro',
                  style: GoogleFonts.interTight(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  themeMode == ThemeMode.system ? 'Sistema' : (isDark ? 'Ativado' : 'Desativado'),
                  style: GoogleFonts.interTight(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: (v) {
              ref.read(themeModeProvider.notifier).definir(v ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    required Color textPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.interTight(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right_rounded, color: textPrimary.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutBtn(BuildContext context, WidgetRef ref, bool isDark) {
    return OutlinedButton.icon(
      onPressed: () => _confirmarLogout(context, ref),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: Text(
        'Sair da conta',
        style: GoogleFonts.interTight(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.expense,
        side: BorderSide(color: AppColors.expense.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  void _abrirSobre(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color border) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: AppColors.gradientPrimary), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('AquiBank', style: GoogleFonts.interTight(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
            Text('Versão 1.0.0', style: GoogleFonts.interTight(color: textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            Text(
              'O AquiBank é um aplicativo financeiro moderno desenvolvido para ajudar você a se estabelecer e se manter estável financeiramente.\n\nCom ele, você pode registrar entradas e despesas, acompanhar seu fluxo de caixa em tempo real, visualizar relatórios detalhados por categoria e período, e tomar decisões financeiras mais inteligentes.\n\nNosso objetivo é democratizar o controle financeiro pessoal, tornando-o acessível, intuitivo e visualmente agradável para todos.',
              style: GoogleFonts.interTight(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text('© 2026 AquiBank. Todos os direitos reservados.', style: GoogleFonts.interTight(color: textSecondary.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _abrirAjuda(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color border) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 20),
            Text('Central de Ajuda', style: GoogleFonts.interTight(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Estamos aqui para te ajudar. Entre em contato conosco:', style: GoogleFonts.interTight(color: textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            _contatoTile(isDark, Icons.phone_rounded, 'WhatsApp / Telefone', '+55 (77) 8108-6867', textPrimary, textSecondary, border),
            const SizedBox(height: 10),
            _contatoTile(isDark, Icons.email_rounded, 'E-mail', 'kevilynbitencourt14@gmail.com', textPrimary, textSecondary, border),
            const SizedBox(height: 20),
            Text('Horário de atendimento: Segunda a Sexta, das 9h às 18h.', style: GoogleFonts.interTight(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _contatoTile(bool isDark, IconData icon, String label, String valor, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.interTight(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(valor, style: GoogleFonts.interTight(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirTermos(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color border) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 16),
              Text('Termos de Uso', style: GoogleFonts.interTight(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
              Text('Atualizado em janeiro de 2026', style: GoogleFonts.interTight(color: textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  child: Text(
                    _termosTexto,
                    style: GoogleFonts.interTight(color: textSecondary, fontSize: 13, height: 1.7, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirPrivacidade(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color border) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 16),
              Text('Política de Privacidade', style: GoogleFonts.interTight(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
              Text('Atualizado em janeiro de 2026 — Conforme LGPD', style: GoogleFonts.interTight(color: textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  child: Text(
                    _privacidadeTexto,
                    style: GoogleFonts.interTight(color: textSecondary, fontSize: 13, height: 1.7, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _termosTexto = '''
1. ACEITAÇÃO DOS TERMOS

Ao utilizar o AquiBank, você concorda com estes Termos de Uso. Se não concordar, não utilize o aplicativo.

2. DESCRIÇÃO DO SERVIÇO

O AquiBank é um aplicativo de gestão financeira pessoal que permite registrar receitas e despesas, visualizar relatórios e acompanhar seu saldo. O aplicativo não realiza transações bancárias reais nem movimenta dinheiro.

3. ELEGIBILIDADE

O uso do AquiBank é permitido para maiores de 18 anos ou menores acompanhados de responsável legal.

4. RESPONSABILIDADE DO USUÁRIO

• Você é responsável pela veracidade dos dados inseridos.
• Mantenha suas credenciais de acesso em segurança.
• Não utilize o aplicativo para fins ilícitos.

5. PRIVACIDADE E LGPD

O tratamento dos seus dados segue a Lei Geral de Proteção de Dados (Lei nº 13.709/2018 — LGPD). Coletamos apenas dados necessários para o funcionamento do serviço. Consulte nossa Política de Privacidade para detalhes.

6. PROPRIEDADE INTELECTUAL

Todo o conteúdo do AquiBank — interfaces, código, marcas e design — é propriedade exclusiva da AquiBank Tecnologia. É proibida a reprodução sem autorização.

7. LIMITAÇÃO DE RESPONSABILIDADE

O AquiBank não se responsabiliza por decisões financeiras tomadas com base nas informações do aplicativo. As informações têm caráter informativo e não constituem aconselhamento financeiro profissional.

8. ATUALIZAÇÕES

Reservamo-nos o direito de atualizar estes termos a qualquer momento. O uso continuado após a atualização implica aceitação dos novos termos.

9. CONTATO

Dúvidas: heliojr7802@gmail.com | +55 (77) 98819-7912
''';

  static const _privacidadeTexto = '''
POLÍTICA DE PRIVACIDADE — LGPD

1. CONTROLADOR DOS DADOS

AquiBank Tecnologia é o controlador responsável pelo tratamento dos seus dados pessoais, conforme a LGPD (Lei nº 13.709/2018).

2. DADOS COLETADOS

• Dados de identificação: nome e endereço de e-mail.
• Dados financeiros: transações, valores, categorias e datas registradas por você.
• Dados de uso: preferências do aplicativo (tema, foto de perfil).

3. FINALIDADE DO TRATAMENTO

• Prestação do serviço de gestão financeira pessoal.
• Autenticação e segurança da conta.
• Melhoria contínua do aplicativo.

4. BASE LEGAL

O tratamento é realizado com base no consentimento do titular (Art. 7º, I, LGPD) e na execução do contrato de prestação de serviço (Art. 7º, V, LGPD).

5. COMPARTILHAMENTO

Seus dados NÃO são vendidos, alugados ou compartilhados com terceiros para fins comerciais. O compartilhamento ocorre apenas quando necessário para prestação do serviço (ex.: infraestrutura de nuvem) ou por obrigação legal.

6. RETENÇÃO

Os dados são mantidos enquanto sua conta estiver ativa. Ao excluir a conta, os dados são removidos em até 30 dias.

7. SEUS DIREITOS (Art. 18 LGPD)

Você tem direito a: confirmação do tratamento, acesso, correção, anonimização, portabilidade, eliminação e revogação do consentimento.

8. SEGURANÇA

Adotamos medidas técnicas e organizacionais para proteger seus dados contra acesso não autorizado, perda e alteração.

9. CONTATO DO DPO

heliojr7802@gmail.com | +55 (77) 98819-7912
''';

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Sair da conta',
          style: GoogleFonts.interTight(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Tem certeza que deseja sair?',
          style: GoogleFonts.interTight(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.interTight(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              navegarParaLogin(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Sair', style: GoogleFonts.interTight(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _confirmarLimpar(BuildContext context, WidgetRef ref, bool isDark, Color border) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Limpar transações',
          style: GoogleFonts.interTight(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Todas as transações serão excluídas permanentemente. Essa ação não pode ser desfeita.',
          style: GoogleFonts.interTight(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.interTight(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = ref.read(authProvider);
              if (auth.usuarioId == null) return;
              await ref.read(contaProvider.notifier).limparTudo(auth.usuarioId!);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Transações removidas.',
                    style: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: AppColors.expense,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.all(12),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Limpar', style: GoogleFonts.interTight(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
