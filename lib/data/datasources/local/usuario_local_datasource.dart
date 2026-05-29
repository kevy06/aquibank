import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/usuario.dart';
import '../../database/database_helper.dart';

class UsuarioLocalDatasource {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<void> salvar(Usuario usuario) async {
    if (usuario.id == null) return;
    final db = await _db;
    await db.insert(
      'usuarios',
      usuario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Usuario?> buscarPorId(String id) async {
    final db = await _db;
    final rows = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Usuario.fromMap(rows.first);
  }

  Future<Usuario?> buscarPorEmail(String email) async {
    final db = await _db;
    final rows = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Usuario.fromMap(rows.first);
  }
}
