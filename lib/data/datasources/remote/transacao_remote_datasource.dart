import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/movimentacao.dart';

class TransacaoRemoteDatasource {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Movimentacao>> listar(String usuarioId) async {
    final data = await _client
        .from('transacoes')
        .select()
        .eq('usuario_id', usuarioId)
        .order('data', ascending: false);
    return (data as List<dynamic>)
        .map((e) => Movimentacao.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvar(Movimentacao m) async {
    await _client.from('transacoes').upsert(m.toMap());
  }

  Future<void> excluir(String id) async {
    await _client.from('transacoes').delete().eq('id', id);
  }

  Future<void> excluirPorUsuario(String usuarioId) async {
    await _client.from('transacoes').delete().eq('usuario_id', usuarioId);
  }
}
