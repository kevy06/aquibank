import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../gerenciadores/conta_gerenciador.dart';
import '../gerenciadores/login_gerenciador.dart';
import '../modelos/movimentacao.dart';

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> with TickerProviderStateMixin {
  static const _azul = Color(0xFF0D47A1);
  static const _azulClaro = Color(0xFF2979FF);
  static const _fundo = Color(0xFFF3F7FE);
  static const _texto = Color(0xFF10243E);
  static const _textoSuave = Color(0xFF6B7A90);
  static const _entrada = Color(0xFF0F8F6D);
  static const _saida = Color(0xFFE65100);

  late final AnimationController _entradaCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fade = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContaGerenciador>().carregarExemplos();
      _entradaCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatoData = DateFormat('dd/MM');
    final hoje = DateTime.now();
    final mesAtual = DateTime(hoje.year, hoje.month);

    return Scaffold(
      backgroundColor: _fundo,
      body: Consumer<ContaGerenciador>(
        builder: (context, contaVM, _) {
          final entradasMes = contaVM.entradasDoMesSelecionado(mesAtual);
          final saidasMes = contaVM.saidasDoMesSelecionado(mesAtual);
          final saldoMes = contaVM.saldoDoMesSelecionado(mesAtual);
          final usoMes =
              entradasMes > 0 ? (saidasMes / entradasMes).clamp(0.0, 1.0) : 0.0;

          return SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    SliverToBoxAdapter(
                      child: _buildBalanceCard(contaVM, formatoMoeda),
                    ),
                    SliverToBoxAdapter(child: _buildQuickActions(context)),
                    SliverToBoxAdapter(
                      child: _buildResumoDoMes(
                        formatoMoeda: formatoMoeda,
                        entradas: entradasMes,
                        saidas: saidasMes,
                        saldo: saldoMes,
                        uso: usoMes,
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildCabecalhoExtrato(context)),
                    if (contaVM.ultimasMovimentacoes.isEmpty)
                      const SliverToBoxAdapter(child: _EstadoVazio())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index.isOdd) return const SizedBox(height: 10);
                            final itemIndex = index ~/ 2;
                            final mov = contaVM.ultimasMovimentacoes[itemIndex];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _MovimentacaoTile(
                                movimentacao: mov,
                                formatoMoeda: formatoMoeda,
                                formatoData: formatoData,
                              ),
                            );
                          },
                          childCount:
                              (_totalUltimas(contaVM.ultimasMovimentacoes) * 2) -
                                  1,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoNovo(context),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        elevation: 10,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Novo lançamento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Consumer<LoginGerenciador>(
            builder: (context, loginVM, _) {
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _azul.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: _azul,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${loginVM.nomeUsuario}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _texto,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sua dashboard financeira',
                            style: TextStyle(
                              color: _textoSuave,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          _HeaderButton(
            icon: Icons.bar_chart_rounded,
            onTap: () => Navigator.pushNamed(context, '/relatorio'),
          ),
          const SizedBox(width: 8),
          _HeaderButton(
            icon: Icons.logout_rounded,
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ContaGerenciador contaVM, NumberFormat formatoMoeda) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        height: 236,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_azul, Color(0xFF1565C0), _azulClaro],
          ),
          boxShadow: [
            BoxShadow(
              color: _azul.withValues(alpha: 0.30),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: 26,
              child: Transform.rotate(
                angle: -0.40,
                child: Container(
                  width: 210,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: -18,
              child: Transform.rotate(
                angle: -0.40,
                child: Container(
                  width: 170,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Text(
                          'AquiBank',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.tune_rounded,
                        color: Colors.white.withValues(alpha: 0.86),
                        size: 22,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Saldo total',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: FittedBox(
                      key: ValueKey(contaVM.saldoAtual),
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatoMoeda.format(contaVM.saldoAtual),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceMetric(
                          label: 'Entradas',
                          value: formatoMoeda.format(contaVM.entradas),
                          icon: Icons.south_west_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      Expanded(
                        child: _BalanceMetric(
                          label: 'Saídas',
                          value: formatoMoeda.format(contaVM.saidas),
                          icon: Icons.north_east_rounded,
                          alignEnd: true,
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

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Entrada',
              icon: Icons.south_west_rounded,
              color: _entrada,
              onTap: () => _abrirDialogoNovo(
                context,
                tipoInicial: TipoMovimentacao.entrada,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'Despesa',
              icon: Icons.north_east_rounded,
              color: _saida,
              onTap: () => _abrirDialogoNovo(
                context,
                tipoInicial: TipoMovimentacao.saida,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'Relatório',
              icon: Icons.query_stats_rounded,
              color: _azul,
              onTap: () => Navigator.pushNamed(context, '/relatorio'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoDoMes({
    required NumberFormat formatoMoeda,
    required double entradas,
    required double saidas,
    required double saldo,
    required double uso,
  }) {
    final status = uso < 0.55
        ? 'Ótimo controle'
        : uso < 0.85
            ? 'Acompanhe de perto'
            : 'Revise seus gastos';
    final corStatus = uso < 0.55
        ? _entrada
        : uso < 0.85
            ? const Color(0xFFFFA000)
            : const Color(0xFFE53935);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _azul.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumo do mês',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: corStatus,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: uso),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, valor, __) {
                  return LinearProgressIndicator(
                    value: valor,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFEAF0FA),
                    valueColor: AlwaysStoppedAnimation<Color>(corStatus),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(uso * 100).toStringAsFixed(0)}% das entradas foram usadas neste mês',
              style: const TextStyle(
                color: _textoSuave,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Entradas',
                    value: formatoMoeda.format(entradas),
                    icon: Icons.trending_up_rounded,
                    color: _entrada,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Saídas',
                    value: formatoMoeda.format(saidas),
                    icon: Icons.trending_down_rounded,
                    color: _saida,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Saldo',
                    value: formatoMoeda.format(saldo),
                    icon: Icons.account_balance_rounded,
                    color: saldo >= 0 ? _azul : const Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalhoExtrato(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: _SectionTitle(
              title: 'Últimos lançamentos',
              subtitle: 'Movimentos recentes da conta',
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/relatorio'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Ver todos'),
            style: TextButton.styleFrom(
              foregroundColor: _azul,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoNovo(
    BuildContext context, {
    TipoMovimentacao? tipoInicial,
  }) {
    final tituloCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    TipoMovimentacao tipoSelecionado = tipoInicial ?? TipoMovimentacao.saida;
    String categoriaSelecionada = _categoriasParaTipo(tipoSelecionado).first;
    String? erro;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final categorias = _categoriasParaTipo(tipoSelecionado);
            if (!categorias.contains(categoriaSelecionada)) {
              categoriaSelecionada = categorias.first;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9E2F0),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _azul.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.add_card_rounded,
                              color: _azul,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Novo lançamento',
                                  style: TextStyle(
                                    color: _texto,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Registre entrada ou despesa',
                                  style: TextStyle(
                                    color: _textoSuave,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _TipoButton(
                              label: 'Entrada',
                              icon: Icons.south_west_rounded,
                              color: _entrada,
                              selected:
                                  tipoSelecionado == TipoMovimentacao.entrada,
                              onTap: () => setSheetState(() {
                                tipoSelecionado = TipoMovimentacao.entrada;
                                categoriaSelecionada =
                                    _categoriasParaTipo(tipoSelecionado).first;
                                erro = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TipoButton(
                              label: 'Despesa',
                              icon: Icons.north_east_rounded,
                              color: _saida,
                              selected: tipoSelecionado == TipoMovimentacao.saida,
                              onTap: () => setSheetState(() {
                                tipoSelecionado = TipoMovimentacao.saida;
                                categoriaSelecionada =
                                    _categoriasParaTipo(tipoSelecionado).first;
                                erro = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CampoFormulario(
                        controlador: tituloCtrl,
                        rotulo: 'Descrição',
                        icone: Icons.edit_note_rounded,
                        acao: TextInputAction.next,
                        capitalizacao: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      _CampoFormulario(
                        controlador: valorCtrl,
                        rotulo: 'Valor',
                        icone: Icons.payments_rounded,
                        tipoTeclado: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        acao: TextInputAction.done,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: categoriaSelecionada,
                        isExpanded: true,
                        decoration: _decoracaoCampo(
                          'Categoria',
                          Icons.category_rounded,
                        ),
                        items: categorias
                            .map(
                              (categoria) => DropdownMenuItem<String>(
                                value: categoria,
                                child: Text(categoria),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) => setSheetState(() {
                          categoriaSelecionada = valor ?? categorias.first;
                          erro = null;
                        }),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: erro == null
                            ? const SizedBox(height: 18)
                            : Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFFCDD2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFE53935),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          erro!,
                                          style: const TextStyle(
                                            color: Color(0xFFE53935),
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
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: tipoSelecionado == TipoMovimentacao.entrada
                                ? const [Color(0xFF08795D), _entrada]
                                : const [Color(0xFFE65100), Color(0xFFFF8A3D)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: (tipoSelecionado ==
                                          TipoMovimentacao.entrada
                                      ? _entrada
                                      : _saida)
                                  .withValues(alpha: 0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final titulo = tituloCtrl.text.trim();
                            final valor = _parseValor(valorCtrl.text);

                            if (titulo.isEmpty) {
                              setSheetState(
                                () => erro = 'Informe uma descrição.',
                              );
                              return;
                            }
                            if (valor == null || valor <= 0) {
                              setSheetState(
                                () => erro = 'Informe um valor válido.',
                              );
                              return;
                            }

                            context.read<ContaGerenciador>().novaMovimentacao(
                                  titulo: titulo,
                                  valor: valor,
                                  tipo: tipoSelecionado,
                                  categoria: categoriaSelecionada,
                                );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tipoSelecionado == TipoMovimentacao.entrada
                                      ? 'Entrada adicionada'
                                      : 'Despesa adicionada',
                                ),
                                backgroundColor: _azul,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Salvar lançamento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
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
            );
          },
        );
      },
    ).whenComplete(() {
      tituloCtrl.dispose();
      valorCtrl.dispose();
    });
  }

  static List<String> _categoriasParaTipo(TipoMovimentacao tipo) {
    if (tipo == TipoMovimentacao.entrada) {
      return const ['Salário', 'Freelance', 'Vendas', 'Investimentos', 'Outros'];
    }
    return const [
      'Alimentação',
      'Moradia',
      'Transporte',
      'Assinaturas',
      'Contas',
      'Compras',
      'Saúde',
      'Outros',
    ];
  }

  static double? _parseValor(String texto) {
    var limpo = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    limpo = limpo.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.isEmpty) return null;

    final temVirgula = limpo.contains(',');
    final temPonto = limpo.contains('.');

    if (temVirgula && temPonto) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    } else if (temVirgula) {
      limpo = limpo.replaceAll(',', '.');
    }

    return double.tryParse(limpo);
  }

  static int _totalUltimas(List<Movimentacao> movimentacoes) {
    return movimentacoes.length > 6 ? 6 : movimentacoes.length;
  }

  static InputDecoration _decoracaoCampo(String rotulo, IconData icone) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(
        color: _textoSuave,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icone, color: _azul),
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
        borderSide: const BorderSide(color: _azul, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE5ECF7)),
          ),
          child: Icon(icon, color: _TelaHomeState._azul, size: 21),
        ),
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool alignEnd;

  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5ECF7)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              FittedBox(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _TelaHomeState._texto,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: _TelaHomeState._textoSuave,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _TelaHomeState._texto,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: _TelaHomeState._textoSuave,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MovimentacaoTile extends StatelessWidget {
  final Movimentacao movimentacao;
  final NumberFormat formatoMoeda;
  final DateFormat formatoData;

  const _MovimentacaoTile({
    required this.movimentacao,
    required this.formatoMoeda,
    required this.formatoData,
  });

  @override
  Widget build(BuildContext context) {
    final entrada = movimentacao.tipo == TipoMovimentacao.entrada;
    final cor =
        entrada ? _TelaHomeState._entrada : _TelaHomeState._saida;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              entrada ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: cor,
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
                  style: const TextStyle(
                    color: _TelaHomeState._texto,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      movimentacao.categoria,
                      style: const TextStyle(
                        color: _TelaHomeState._textoSuave,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatoData.format(movimentacao.data),
                      style: const TextStyle(
                        color: Color(0xFF9AA8BB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${entrada ? '+' : '-'} ${formatoMoeda.format(movimentacao.valor)}',
                style: TextStyle(
                  color: cor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TipoButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? color : const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? color : const Color(0xFFE2EAF7),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : _TelaHomeState._texto,
                    fontWeight: FontWeight.w900,
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

class _CampoFormulario extends StatelessWidget {
  final TextEditingController controlador;
  final String rotulo;
  final IconData icone;
  final TextInputType? tipoTeclado;
  final TextInputAction? acao;
  final TextCapitalization capitalizacao;

  const _CampoFormulario({
    required this.controlador,
    required this.rotulo,
    required this.icone,
    this.tipoTeclado,
    this.acao,
    this.capitalizacao = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      keyboardType: tipoTeclado,
      textInputAction: acao,
      textCapitalization: capitalizacao,
      style: const TextStyle(
        color: _TelaHomeState._texto,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: _TelaHomeState._decoracaoCampo(rotulo, icone),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5ECF7)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: _TelaHomeState._azul,
              size: 38,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum lançamento cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _TelaHomeState._texto,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Use o botão de novo lançamento para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _TelaHomeState._textoSuave,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
