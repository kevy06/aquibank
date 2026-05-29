import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/movimentacao.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/movimentacao_tile.dart';
import '../../../shared/widgets/shimmer_card.dart';

class TelaExtrato extends ConsumerStatefulWidget {
  const TelaExtrato({super.key});

  @override
  ConsumerState<TelaExtrato> createState() => _TelaExtratoState();
}

class _TelaExtratoState extends ConsumerState<TelaExtrato>
    with AutomaticKeepAliveClientMixin {
  final _buscaCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final conta = ref.watch(contaProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCabecalho(context, isDark),
            _buildBusca(context, conta, isDark),
            _buildFiltros(context, conta, isDark),
            Expanded(
              child: conta.isLoading
                  ? const ShimmerList(count: 6)
                  : _buildLista(context, conta, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extrato',
                  style: GoogleFonts.interTight(
                    color: context.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Consumer(
                  builder: (_, ref, __) {
                    final total = ref.watch(contaProvider).filtradas.length;
                    return Text(
                      '$total lançamentos',
                      style: GoogleFonts.interTight(
                        color: context.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _BotaoFiltroAtivo(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildBusca(BuildContext context, ContaState conta, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: TextField(
        controller: _buscaCtrl,
        onChanged: (v) => ref.read(contaProvider.notifier).buscar(v),
        style: GoogleFonts.interTight(
          color: context.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar lançamentos...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: conta.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _buscaCtrl.clear();
                    ref.read(contaProvider.notifier).buscar('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context, ContaState conta, bool isDark) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FiltroChip(
            label: 'Todos',
            selecionado: conta.tipoFiltro == null,
            isDark: isDark,
            onTap: () => ref.read(contaProvider.notifier).filtrarTipo(null),
          ),
          const SizedBox(width: 8),
          _FiltroChip(
            label: 'Entradas',
            selecionado: conta.tipoFiltro == TipoMovimentacao.entrada,
            cor: AppColors.income,
            isDark: isDark,
            onTap: () => ref
                .read(contaProvider.notifier)
                .filtrarTipo(TipoMovimentacao.entrada),
          ),
          const SizedBox(width: 8),
          _FiltroChip(
            label: 'Saídas',
            selecionado: conta.tipoFiltro == TipoMovimentacao.saida,
            cor: AppColors.expense,
            isDark: isDark,
            onTap: () => ref
                .read(contaProvider.notifier)
                .filtrarTipo(TipoMovimentacao.saida),
          ),
          const SizedBox(width: 8),
          ...Movimentacao.categoriasSaida.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FiltroChip(
                  label: cat,
                  selecionado: conta.categoriaFiltro == cat,
                  cor: accent,
                  isDark: isDark,
                  onTap: () => ref
                      .read(contaProvider.notifier)
                      .filtrarCategoria(conta.categoriaFiltro == cat ? null : cat),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLista(BuildContext context, ContaState conta, bool isDark) {
    final lista = conta.filtradas;

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Nenhum lançamento encontrado',
              style: GoogleFonts.interTight(
                color: context.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tente ajustar os filtros.',
              style: GoogleFonts.interTight(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
            if (conta.tipoFiltro != null ||
                conta.categoriaFiltro != null ||
                conta.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _buscaCtrl.clear();
                  ref.read(contaProvider.notifier).limparFiltros();
                },
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    // Group by month
    final grupos = <String, List<Movimentacao>>{};
    for (final m in lista) {
      final chave = chaveMes(m.data);
      grupos.putIfAbsent(chave, () => []).add(m);
    }
    final meses = grupos.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: meses.length,
      itemBuilder: (_, mi) {
        final chave = meses[mi];
        final movs = grupos[chave]!;
        final mesData = DateTime(int.parse(chave.split('-')[0]), int.parse(chave.split('-')[1]));
        final totalEntradas = movs.where((m) => m.tipo == TipoMovimentacao.entrada).fold(0.0, (s, m) => s + m.valor);
        final totalSaidas = movs.where((m) => m.tipo == TipoMovimentacao.saida).fold(0.0, (s, m) => s + m.valor);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nomeMes(mesData),
                      style: GoogleFonts.interTight(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '+${formatarMoeda(totalEntradas)}',
                    style: GoogleFonts.interTight(
                      color: AppColors.income,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${formatarMoeda(totalSaidas)}',
                    style: GoogleFonts.interTight(
                      color: AppColors.expense,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ...movs.map((mov) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: MovimentacaoTile(
                    movimentacao: mov,
                    dataCompleta: true,
                    onEditar: () => _abrirEdicao(context, mov),
                    onExcluir: () => ref.read(contaProvider.notifier).excluir(mov.id),
                  ),
                )),
          ],
        );
      },
    );
  }

  void _abrirEdicao(BuildContext context, Movimentacao mov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEdicao(movimentacao: mov),
    );
  }
}

class _BotaoFiltroAtivo extends ConsumerWidget {
  final bool isDark;
  const _BotaoFiltroAtivo({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conta = ref.watch(contaProvider);
    final ativo = conta.tipoFiltro != null || conta.categoriaFiltro != null;
    return IconButton(
      onPressed: ativo
          ? () => ref.read(contaProvider.notifier).limparFiltros()
          : null,
      icon: Icon(
        ativo ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
        color: ativo
            ? (isDark ? AppColors.primaryLight : AppColors.primary)
            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final Color? cor;
  final bool isDark;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selecionado,
    this.cor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = cor ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? c : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selecionado ? c : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.interTight(
            color: selecionado ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Formulário de edição ────────────────────────────────────────────────────

class _FormularioEdicao extends ConsumerStatefulWidget {
  final Movimentacao movimentacao;
  const _FormularioEdicao({required this.movimentacao});

  @override
  ConsumerState<_FormularioEdicao> createState() => _FormularioEdicaoState();
}

class _FormularioEdicaoState extends ConsumerState<_FormularioEdicao> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _valorCtrl;
  late String _categoria;
  late DateTime _data;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.movimentacao.titulo);
    _valorCtrl = TextEditingController(
        text: widget.movimentacao.valor.toStringAsFixed(2).replaceAll('.', ','));
    _categoria = widget.movimentacao.categoria;
    _data = widget.movimentacao.data;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final valorTxt = _valorCtrl.text.trim().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    final valor = double.tryParse(valorTxt);
    if (valor == null || valor <= 0) return;

    await ref.read(contaProvider.notifier).editar(
          widget.movimentacao.copyWith(
            titulo: _tituloCtrl.text.trim(),
            valor: valor,
            categoria: _categoria,
            data: _data,
          ),
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = context.border;
    final textPrimary = context.textPrimary;
    final categorias = Movimentacao.categoriasParaTipo(widget.movimentacao.tipo);
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
                    width: 42, height: 4,
                    decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Editar lançamento',
                  style: GoogleFonts.interTight(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _tituloCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe uma descrição.' : null,
                  decoration: const InputDecoration(labelText: 'Descrição', prefixIcon: Icon(Icons.edit_note_rounded)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o valor.';
                    final n = double.tryParse(v.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (n == null || n <= 0) return 'Valor inválido.';
                    return null;
                  },
                  decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixIcon: Icon(Icons.payments_rounded)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoria', prefixIcon: Icon(Icons.category_rounded)),
                  items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _categoria = v ?? _categoria),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _data,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (d != null) setState(() => _data = d);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Data', prefixIcon: Icon(Icons.calendar_today_rounded)),
                    child: Text(
                      formatarData(_data),
                      style: GoogleFonts.interTight(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.check_rounded),
                  label: Text('Salvar alterações', style: GoogleFonts.interTight(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
