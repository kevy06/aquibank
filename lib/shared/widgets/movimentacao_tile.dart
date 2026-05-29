import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/movimentacao.dart';

IconData _iconForCategoria(String categoria) => switch (categoria) {
  'Alimentação' => Icons.restaurant_rounded,
  'Moradia' => Icons.home_rounded,
  'Transporte' => Icons.directions_car_rounded,
  'Assinaturas' => Icons.subscriptions_rounded,
  'Contas' => Icons.receipt_long_rounded,
  'Compras' => Icons.shopping_bag_rounded,
  'Saúde' => Icons.favorite_rounded,
  'Lazer' => Icons.sports_esports_rounded,
  'Salário' => Icons.work_rounded,
  'Freelance' => Icons.laptop_mac_rounded,
  'Vendas' => Icons.storefront_rounded,
  'Investimentos' => Icons.trending_up_rounded,
  'Bônus' => Icons.card_giftcard_rounded,
  _ => Icons.swap_vert_rounded,
};

class MovimentacaoTile extends StatelessWidget {
  final Movimentacao movimentacao;
  final VoidCallback? onExcluir;
  final VoidCallback? onEditar;
  final bool dataCompleta;

  const MovimentacaoTile({
    super.key,
    required this.movimentacao,
    this.onExcluir,
    this.onEditar,
    this.dataCompleta = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entrada = movimentacao.tipo == TipoMovimentacao.entrada;
    final cor = entrada ? AppColors.income : AppColors.expense;
    final corSubtleLight = entrada ? AppColors.incomeSubtleLight : AppColors.expenseSubtleLight;
    final corSubtleDark = entrada ? AppColors.incomeSubtle : AppColors.expenseSubtle;
    final corSubtle = isDark ? corSubtleDark : corSubtleLight;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    Widget tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: corSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForCategoria(movimentacao.categoria),
              color: cor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimentacao.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.interTight(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(label: movimentacao.categoria, isDark: isDark),
                    const SizedBox(width: 6),
                    Text(
                      dataCompleta
                          ? formatarData(movimentacao.data)
                          : formatarDiaMes(movimentacao.data),
                      style: GoogleFonts.interTight(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${entrada ? '+' : '-'} ${formatarMoeda(movimentacao.valor)}',
                    style: GoogleFonts.interTight(
                      color: cor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (onEditar != null)
                GestureDetector(
                  onTap: onEditar,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Editar',
                      style: GoogleFonts.interTight(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onExcluir == null) return tile;

    return Dismissible(
      key: Key(movimentacao.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Excluir lançamento?',
              style: GoogleFonts.interTight(fontWeight: FontWeight.w900),
            ),
            content: Text(
              'Esta ação não pode ser desfeita.',
              style: GoogleFonts.interTight(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onExcluir!(),
      child: tile,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Chip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.interTight(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
