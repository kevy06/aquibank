import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/movimentacao.dart';
import '../../../providers/app_providers.dart';
import '../../home/views/tela_home.dart';
import '../../extrato/views/tela_extrato.dart';
import '../../noticias/views/tela_noticias.dart';
import '../../perfil/views/tela_perfil.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  int _indice = 0;

  static const _paginas = [
    TelaHome(),
    TelaExtrato(),
    TelaNoticias(),
    TelaPerfil(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: IndexedStack(index: _indice, children: _paginas),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _indice > 1 ? _indice + 1 : _indice,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (i) {
            if (i == 2) return;
            setState(() => _indice = i > 2 ? i - 1 : i);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'Extrato',
            ),
            const NavigationDestination(
              icon: SizedBox(width: 56),
              label: '',
              tooltip: '',
            ),
            const NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper_rounded),
              label: 'Notícias',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _abrirNovoLancamento(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  void _abrirNovoLancamento(BuildContext context, {TipoMovimentacao? tipoInicial}) {
    final auth = ref.read(authProvider);
    if (auth.usuarioId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioLancamento(
        tipoInicial: tipoInicial,
        usuarioId: auth.usuarioId!,
      ),
    );
  }
}

class _FormularioLancamento extends ConsumerStatefulWidget {
  final TipoMovimentacao? tipoInicial;
  final String usuarioId;

  const _FormularioLancamento({this.tipoInicial, required this.usuarioId});

  @override
  ConsumerState<_FormularioLancamento> createState() => _FormularioLancamentoState();
}

class _FormularioLancamentoState extends ConsumerState<_FormularioLancamento> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late TipoMovimentacao _tipo;
  late String _categoria;
  DateTime _data = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial ?? TipoMovimentacao.saida;
    _categoria = Movimentacao.categoriasParaTipo(_tipo).first;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _valorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) setState(() => _data = data);
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final valor = parseCurrency(_valorCtrl.text);
    if (valor <= 0) return;

    await ref.read(contaProvider.notifier).adicionar(
          usuarioId: widget.usuarioId,
          titulo: _tituloCtrl.text.trim(),
          valor: valor,
          tipo: _tipo,
          categoria: _categoria,
          descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          data: _data,
        );

    // Dispara notificação
    ref.read(notificacaoProvider.notifier).adicionar(AppNotificacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: _tipo == TipoMovimentacao.entrada ? 'Entrada registrada' : 'Despesa registrada',
      mensagem: '${_tituloCtrl.text.trim()} — ${_valorCtrl.text}',
      criadoEm: DateTime.now(),
    ));

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tipo == TipoMovimentacao.entrada ? 'Entrada adicionada!' : 'Despesa adicionada!',
          style: GoogleFonts.interTight(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _tipo == TipoMovimentacao.entrada ? AppColors.income : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final categorias = Movimentacao.categoriasParaTipo(_tipo);

    if (!categorias.contains(_categoria)) _categoria = categorias.first;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Novo lançamento',
                  style: GoogleFonts.interTight(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _TipoBtn(
                      label: 'Entrada',
                      icon: Icons.south_west_rounded,
                      cor: AppColors.income,
                      selecionado: _tipo == TipoMovimentacao.entrada,
                      onTap: () => setState(() {
                        _tipo = TipoMovimentacao.entrada;
                        _categoria = Movimentacao.categoriasParaTipo(_tipo).first;
                      }),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _TipoBtn(
                      label: 'Despesa',
                      icon: Icons.north_east_rounded,
                      cor: AppColors.expense,
                      selecionado: _tipo == TipoMovimentacao.saida,
                      onTap: () => setState(() {
                        _tipo = TipoMovimentacao.saida;
                        _categoria = Movimentacao.categoriasParaTipo(_tipo).first;
                      }),
                    )),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _tituloCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe uma descrição.' : null,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o valor.';
                    if (parseCurrency(v) <= 0) return 'Valor inválido.';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    hintText: 'R\$ 0,00',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v ?? _categoria),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selecionarData,
                  borderRadius: BorderRadius.circular(18),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: textSecondary),
                    ),
                    child: Text(
                      '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
                      style: GoogleFonts.interTight(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _tipo == TipoMovimentacao.entrada
                          ? AppColors.gradientIncome
                          : AppColors.gradientExpense,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (_tipo == TipoMovimentacao.entrada
                                ? AppColors.income
                                : AppColors.expense)
                            .withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      'Salvar lançamento',
                      style: GoogleFonts.interTight(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

class _TipoBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  const _TipoBtn({
    required this.label,
    required this.icon,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selecionado ? cor : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selecionado ? cor : AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selecionado ? Colors.white : cor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.interTight(
                    color: selecionado ? Colors.white : null,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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

// Re-expose for use in other screens
void abrirFormularioLancamento(
  BuildContext context,
  WidgetRef ref, {
  TipoMovimentacao? tipoInicial,
}) {
  final auth = ref.read(authProvider);
  if (auth.usuarioId == null) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FormularioLancamento(
      tipoInicial: tipoInicial,
      usuarioId: auth.usuarioId!,
    ),
  );
}

// Helper to navigate back to root and trigger logout
void navegarParaLogin(BuildContext context, WidgetRef ref) {
  ref.read(contaProvider.notifier).limpar();
  ref.read(authProvider.notifier).logout();
  Navigator.pushReplacementNamed(context, AppRoutes.login);
}
