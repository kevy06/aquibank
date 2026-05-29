import 'package:uuid/uuid.dart';
import '../../domain/entities/movimentacao.dart';
import '../../domain/repositories/conta_repository.dart';
import '../datasources/local/transacao_local_datasource.dart';
import '../datasources/remote/transacao_remote_datasource.dart';

const _uuid = Uuid();

class ContaRepositoryImpl implements ContaRepository {
  final TransacaoLocalDatasource _local;
  final TransacaoRemoteDatasource _remote;

  const ContaRepositoryImpl({
    required TransacaoLocalDatasource local,
    required TransacaoRemoteDatasource remote,
  })  : _local = local,
        _remote = remote;

  @override
  Future<List<Movimentacao>> listar(String usuarioId) async {
    await _sincronizarPendentes(usuarioId);

    try {
      final remotas = await _remote.listar(usuarioId);
      await _local.substituirSincronizadas(usuarioId, remotas);
    } catch (_) {}

    return _local.listar(usuarioId);
  }

  @override
  Future<void> inserir(Movimentacao movimentacao) async {
    await _local.inserir(movimentacao);
    try {
      await _remote.salvar(movimentacao);
      await _local.marcarSincronizada(movimentacao.id);
    } catch (_) {}
  }

  @override
  Future<void> atualizar(Movimentacao movimentacao) async {
    await _local.atualizar(movimentacao);
    try {
      await _remote.salvar(movimentacao);
      await _local.marcarSincronizada(movimentacao.id);
    } catch (_) {}
  }

  @override
  Future<void> excluir(String id) async {
    await _local.marcarExcluida(id);
    try {
      await _remote.excluir(id);
      await _local.excluir(id);
    } catch (_) {}
  }

  Future<void> excluirTodos(String usuarioId) async {
    await _local.excluirPorUsuario(usuarioId);
    try {
      await _remote.excluirPorUsuario(usuarioId);
      await _local.excluirDefinitivoPorUsuario(usuarioId);
    } catch (_) {}
  }

  Future<bool> precisaSeed(String usuarioId) async {
    final total = await _local.contarPorUsuario(usuarioId);
    return total == 0;
  }

  Future<void> _sincronizarPendentes(String usuarioId) async {
    try {
      final exclusoes = await _local.exclusoesPendentes(usuarioId);
      for (final id in exclusoes) {
        await _remote.excluir(id);
        await _local.excluir(id);
      }

      final pendentes = await _local.pendentes(usuarioId);
      for (final mov in pendentes) {
        await _remote.salvar(mov);
        await _local.marcarSincronizada(mov.id);
      }
    } catch (_) {}
  }

  Future<void> semearExemplos(String usuarioId) async {
    final agora = DateTime.now();

    final exemplos = <({String titulo, double valor, TipoMovimentacao tipo, int deslMes, int dia, String cat})>[
      (titulo: 'Salário mensal', valor: 4500, tipo: TipoMovimentacao.entrada, deslMes: 0, dia: 1, cat: 'Salário'),
      (titulo: 'Projeto freelancer', valor: 800, tipo: TipoMovimentacao.entrada, deslMes: 0, dia: 8, cat: 'Freelance'),
      (titulo: 'Venda online', valor: 250, tipo: TipoMovimentacao.entrada, deslMes: 0, dia: 12, cat: 'Vendas'),
      (titulo: 'Aluguel', valor: 1200, tipo: TipoMovimentacao.saida, deslMes: 0, dia: 2, cat: 'Moradia'),
      (titulo: 'Supermercado', valor: 380, tipo: TipoMovimentacao.saida, deslMes: 0, dia: 10, cat: 'Alimentação'),
      (titulo: 'Energia elétrica', valor: 210, tipo: TipoMovimentacao.saida, deslMes: 0, dia: 6, cat: 'Contas'),
      (titulo: 'Transporte', valor: 150, tipo: TipoMovimentacao.saida, deslMes: 0, dia: 15, cat: 'Transporte'),
      (titulo: 'Assinaturas', valor: 45.90, tipo: TipoMovimentacao.saida, deslMes: 0, dia: 18, cat: 'Assinaturas'),
      (titulo: 'Salário mensal', valor: 4500, tipo: TipoMovimentacao.entrada, deslMes: -1, dia: 5, cat: 'Salário'),
      (titulo: 'Freelance app', valor: 600, tipo: TipoMovimentacao.entrada, deslMes: -1, dia: 18, cat: 'Freelance'),
      (titulo: 'Aluguel', valor: 1200, tipo: TipoMovimentacao.saida, deslMes: -1, dia: 3, cat: 'Moradia'),
      (titulo: 'Supermercado', valor: 420, tipo: TipoMovimentacao.saida, deslMes: -1, dia: 10, cat: 'Alimentação'),
      (titulo: 'Conta de luz', valor: 198, tipo: TipoMovimentacao.saida, deslMes: -1, dia: 8, cat: 'Contas'),
      (titulo: 'Uber e ônibus', valor: 89, tipo: TipoMovimentacao.saida, deslMes: -1, dia: 15, cat: 'Transporte'),
      (titulo: 'Streaming', valor: 65.90, tipo: TipoMovimentacao.saida, deslMes: -1, dia: 12, cat: 'Assinaturas'),
      (titulo: 'Salário mensal', valor: 4500, tipo: TipoMovimentacao.entrada, deslMes: -2, dia: 5, cat: 'Salário'),
      (titulo: 'Aluguel', valor: 1200, tipo: TipoMovimentacao.saida, deslMes: -2, dia: 3, cat: 'Moradia'),
      (titulo: 'Supermercado', valor: 350, tipo: TipoMovimentacao.saida, deslMes: -2, dia: 12, cat: 'Alimentação'),
      (titulo: 'Energia + Internet', valor: 295, tipo: TipoMovimentacao.saida, deslMes: -2, dia: 7, cat: 'Contas'),
      (titulo: 'Jantar restaurante', valor: 120, tipo: TipoMovimentacao.saida, deslMes: -2, dia: 22, cat: 'Lazer'),
      (titulo: 'Salário mensal', valor: 4500, tipo: TipoMovimentacao.entrada, deslMes: -3, dia: 5, cat: 'Salário'),
      (titulo: 'Bônus empresa', valor: 1000, tipo: TipoMovimentacao.entrada, deslMes: -3, dia: 15, cat: 'Bônus'),
      (titulo: 'Aluguel', valor: 1200, tipo: TipoMovimentacao.saida, deslMes: -3, dia: 3, cat: 'Moradia'),
      (titulo: 'Supermercado', valor: 310, tipo: TipoMovimentacao.saida, deslMes: -3, dia: 9, cat: 'Alimentação'),
      (titulo: 'Viagem', valor: 800, tipo: TipoMovimentacao.saida, deslMes: -3, dia: 20, cat: 'Lazer'),
      (titulo: 'Contas do mês', valor: 290, tipo: TipoMovimentacao.saida, deslMes: -3, dia: 7, cat: 'Contas'),
      (titulo: 'Salário mensal', valor: 4500, tipo: TipoMovimentacao.entrada, deslMes: -4, dia: 5, cat: 'Salário'),
      (titulo: '13° salário', valor: 2250, tipo: TipoMovimentacao.entrada, deslMes: -4, dia: 2, cat: 'Bônus'),
      (titulo: 'Aluguel', valor: 1200, tipo: TipoMovimentacao.saida, deslMes: -4, dia: 3, cat: 'Moradia'),
      (titulo: 'IPTU', valor: 380, tipo: TipoMovimentacao.saida, deslMes: -4, dia: 10, cat: 'Contas'),
      (titulo: 'Supermercado', valor: 430, tipo: TipoMovimentacao.saida, deslMes: -4, dia: 16, cat: 'Alimentação'),
      (titulo: 'Salário mensal', valor: 4500, tipo: TipoMovimentacao.entrada, deslMes: -5, dia: 5, cat: 'Salário'),
      (titulo: 'Venda equipamentos', valor: 700, tipo: TipoMovimentacao.entrada, deslMes: -5, dia: 18, cat: 'Vendas'),
      (titulo: 'Aluguel', valor: 1200, tipo: TipoMovimentacao.saida, deslMes: -5, dia: 3, cat: 'Moradia'),
      (titulo: 'Supermercado', valor: 390, tipo: TipoMovimentacao.saida, deslMes: -5, dia: 14, cat: 'Alimentação'),
      (titulo: 'Contas do mês', valor: 210, tipo: TipoMovimentacao.saida, deslMes: -5, dia: 7, cat: 'Contas'),
    ];

    for (final e in exemplos) {
      final base = DateTime(agora.year, agora.month + e.deslMes);
      final ultimoDia = DateTime(base.year, base.month + 1, 0).day;
      final dia = e.dia > ultimoDia ? ultimoDia : e.dia;
      final data = DateTime(base.year, base.month, dia);

      await inserir(Movimentacao(
        id: _uuid.v4(),
        usuarioId: usuarioId,
        titulo: e.titulo,
        valor: e.valor,
        tipo: e.tipo,
        categoria: e.cat,
        data: data,
        criadoEm: agora,
      ));
    }
  }
}
