import '../entities/movimentacao.dart';

abstract class ContaRepository {
  Future<List<Movimentacao>> listar(String usuarioId);
  Future<void> inserir(Movimentacao movimentacao);
  Future<void> atualizar(Movimentacao movimentacao);
  Future<void> excluir(String id);
}
