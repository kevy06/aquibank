import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/movimentacao.dart';
import '../../database/database_helper.dart';

class TransacaoLocalDatasource {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Map<String, dynamic> _toDbMap(
    Movimentacao m, {
    required bool sincronizado,
    bool excluido = false,
  }) {
    return {
      ...m.toMap(),
      'sincronizado': sincronizado ? 1 : 0,
      'excluido': excluido ? 1 : 0,
      'atualizado_em': DateTime.now().toIso8601String(),
    };
  }

  Future<List<Movimentacao>> listar(String usuarioId) async {
    final db = await _db;
    final rows = await db.query(
      'transacoes',
      where: 'usuario_id = ? AND excluido = 0',
      whereArgs: [usuarioId],
      orderBy: 'data DESC, criado_em DESC',
    );
    return rows.map(Movimentacao.fromMap).toList();
  }

  Future<List<Movimentacao>> pendentes(String usuarioId) async {
    final db = await _db;
    final rows = await db.query(
      'transacoes',
      where: 'usuario_id = ? AND sincronizado = 0 AND excluido = 0',
      whereArgs: [usuarioId],
      orderBy: 'atualizado_em ASC',
    );
    return rows.map(Movimentacao.fromMap).toList();
  }

  Future<List<String>> exclusoesPendentes(String usuarioId) async {
    final db = await _db;
    final rows = await db.query(
      'transacoes',
      columns: ['id'],
      where: 'usuario_id = ? AND sincronizado = 0 AND excluido = 1',
      whereArgs: [usuarioId],
      orderBy: 'atualizado_em ASC',
    );
    return rows.map((row) => row['id'] as String).toList();
  }

  Future<void> inserir(Movimentacao m, {bool sincronizado = false}) async {
    final db = await _db;
    await db.insert(
      'transacoes',
      _toDbMap(m, sincronizado: sincronizado),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> inserirTodos(
    List<Movimentacao> movimentacoes, {
    bool sincronizado = true,
  }) async {
    if (movimentacoes.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (final m in movimentacoes) {
      batch.insert(
        'transacoes',
        _toDbMap(m, sincronizado: sincronizado),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> substituirSincronizadas(
    String usuarioId,
    List<Movimentacao> remotas,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'transacoes',
        where: 'usuario_id = ? AND sincronizado = 1',
        whereArgs: [usuarioId],
      );
      final batch = txn.batch();
      for (final m in remotas) {
        batch.insert(
          'transacoes',
          _toDbMap(m, sincronizado: true),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> atualizar(Movimentacao m, {bool sincronizado = false}) async {
    final db = await _db;
    await db.update(
      'transacoes',
      _toDbMap(m, sincronizado: sincronizado),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<void> marcarSincronizada(String id) async {
    final db = await _db;
    await db.update(
      'transacoes',
      {
        'sincronizado': 1,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarExcluida(String id) async {
    final db = await _db;
    await db.update(
      'transacoes',
      {
        'sincronizado': 0,
        'excluido': 1,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> excluir(String id) async {
    final db = await _db;
    await db.delete('transacoes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> excluirPorUsuario(String usuarioId) async {
    final db = await _db;
    await db.update(
      'transacoes',
      {
        'sincronizado': 0,
        'excluido': 1,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<void> excluirDefinitivoPorUsuario(String usuarioId) async {
    final db = await _db;
    await db.delete(
      'transacoes',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<int> contarPorUsuario(String usuarioId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM transacoes WHERE usuario_id = ? AND excluido = 0',
      [usuarioId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
