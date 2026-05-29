import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/news_service.dart';

class TelaNoticias extends StatefulWidget {
  const TelaNoticias({super.key});

  @override
  State<TelaNoticias> createState() => _TelaNoticiasState();
}

class _TelaNoticiasState extends State<TelaNoticias>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final _service = NewsService();
  List<Noticia> _todas = [];
  List<Noticia> _filtradas = [];
  bool _loading = true;
  int _temaIdx = 0;
  late AnimationController _listCtrl;
  late AnimationController _headerCtrl;

  static const _temas = [
    (label: 'Tudo', tag: ''),
    (label: 'Economia', tag: 'economia'),
    (label: 'Investimentos', tag: 'investimentos'),
    (label: 'Cripto', tag: 'cripto'),
    (label: 'Fintechs', tag: 'fintech'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _headerCtrl.forward();
    _carregar();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    _listCtrl.reset();
    final resultado = await _service.buscarNoticias();
    // Shuffle so refresh actually feels like new content
    resultado.shuffle(Random());
    if (mounted) {
      setState(() {
        _todas = resultado;
        _loading = false;
        _aplicarFiltro();
      });
      _listCtrl.forward();
    }
  }

  void _aplicarFiltro() {
    final tag = _temas[_temaIdx].tag;
    setState(() {
      if (tag.isEmpty) {
        _filtradas = List.from(_todas);
      } else {
        _filtradas = _todas.where((n) => n.tags.contains(tag)).toList();
        if (_filtradas.isEmpty) _filtradas = List.from(_todas);
      }
    });
    _listCtrl.reset();
    _listCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, textPrimary, textSecondary),
            _buildFiltros(isDark, textPrimary),
            const SizedBox(height: 4),
            Expanded(child: _buildBody(isDark, textPrimary, textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return FadeTransition(
      opacity: _headerCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notícias',
                      style: GoogleFonts.interTight(
                        color: textPrimary, fontSize: 26,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5,
                      ),
                    ),
                    Text('Mercado financeiro em tempo real',
                      style: GoogleFonts.interTight(
                        color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : IconButton(
                        key: const ValueKey('refresh'),
                        onPressed: _carregar,
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                        tooltip: 'Atualizar',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros(bool isDark, Color textPrimary) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _temas.length,
        itemBuilder: (_, i) {
          final ativo = _temaIdx == i;
          return GestureDetector(
            onTap: () {
              if (_temaIdx == i) return;
              setState(() => _temaIdx = i);
              _aplicarFiltro();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: ativo ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ativo ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: ativo ? 1.5 : 1,
                ),
                boxShadow: ativo
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Text(_temas[i].label,
                style: GoogleFonts.interTight(
                  color: ativo ? Colors.white : textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isDark, Color textPrimary, Color textSecondary) {
    if (_loading) return _buildShimmer(isDark);
    if (_filtradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper_rounded, size: 52, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 12),
            Text('Nenhuma notícia encontrada.',
              style: GoogleFonts.interTight(color: textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filtradas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final delay = (i * 0.08).clamp(0.0, 0.7);
          final anim = CurvedAnimation(
            parent: _listCtrl,
            curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
          );
          return AnimatedBuilder(
            animation: anim,
            builder: (_, child) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _buildCard(_filtradas[i], isDark, textPrimary, textSecondary),
          );
        },
      ),
    );
  }

  Widget _buildCard(Noticia n, bool isDark, Color textPrimary, Color textSecondary) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final diff = DateTime.now().difference(n.publicadoEm);
    final tempo = diff.inHours < 1 ? '${diff.inMinutes}min atrás'
        : diff.inHours < 24 ? '${diff.inHours}h atrás'
        : '${diff.inDays}d atrás';

    return GestureDetector(
      onTap: () => Navigator.push(context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) => _TelaDetalheNoticia(noticia: n),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.urlImagem != null && n.urlImagem!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(n.urlImagem!, height: 160, width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(n.fonte,
                          style: GoogleFonts.interTight(
                            color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 11, color: textSecondary),
                          const SizedBox(width: 3),
                          Text(tempo,
                            style: GoogleFonts.interTight(
                              color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(n.titulo,
                    style: GoogleFonts.interTight(
                      color: textPrimary, fontSize: 15, fontWeight: FontWeight.w800, height: 1.3),
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                  ),
                  if (n.descricao.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(n.descricao,
                      style: GoogleFonts.interTight(
                        color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (n.tags.isNotEmpty)
                        ...n.tags.take(2).map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.borderDark : const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('#$tag',
                              style: GoogleFonts.interTight(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.primary,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        )),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text('Ler mais',
                              style: GoogleFonts.interTight(
                                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppColors.borderDark : AppColors.borderLight;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final delay = i * 0.1;
        final anim = CurvedAnimation(
          parent: _headerCtrl,
          curve: Interval(delay.clamp(0.0, 0.9), 1.0, curve: Curves.easeOut),
        );
        return FadeTransition(
          opacity: anim,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: base.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tela de detalhe ─────────────────────────────────────────────────────────

class _TelaDetalheNoticia extends StatelessWidget {
  final Noticia noticia;
  const _TelaDetalheNoticia({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final diff = DateTime.now().difference(noticia.publicadoEm);
    final tempo = diff.inHours < 1 ? '${diff.inMinutes} minutos atrás'
        : diff.inHours < 24 ? 'Há ${diff.inHours} horas'
        : 'Há ${diff.inDays} dias';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: bg,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Icon(Icons.arrow_back_rounded, size: 18, color: textPrimary),
                  ),
                ),
              ),
              pinned: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(noticia.fonte,
                      style: GoogleFonts.interTight(
                        color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (noticia.urlImagem != null && noticia.urlImagem!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          noticia.urlImagem!,
                          height: 220, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 5),
                        Text(tempo,
                          style: GoogleFonts.interTight(
                            color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(noticia.titulo,
                      style: GoogleFonts.interTight(
                        color: textPrimary, fontSize: 22,
                        fontWeight: FontWeight.w900, height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 3, width: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      noticia.descricao.isNotEmpty
                          ? noticia.descricao
                          : 'Conteúdo completo disponível na fonte original.',
                      style: GoogleFonts.interTight(
                        color: textSecondary, fontSize: 15,
                        fontWeight: FontWeight.w500, height: 1.7,
                      ),
                    ),
                    if (noticia.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: noticia.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('#$tag',
                            style: GoogleFonts.interTight(
                              color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (noticia.url.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text('Abrir notícia completa',
                            style: GoogleFonts.interTight(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
