import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _databaseName = 'aquibank.db';
  static const _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    final db = _database;
    if (db != null) return db;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await _createTransacoes(db);

    await db.execute(
      'CREATE INDEX idx_transacoes_usuario_data ON transacoes(usuario_id, data)',
    );
    await db.execute(
      'CREATE INDEX idx_transacoes_sync ON transacoes(usuario_id, sincronizado, excluido)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE transacoes RENAME TO transacoes_old');
        await _createTransacoes(txn);
        await txn.execute('''
          INSERT OR REPLACE INTO transacoes (
            id, usuario_id, titulo, valor, tipo, categoria, descricao, data,
            criado_em, sincronizado, excluido, atualizado_em
          )
          SELECT
            id, usuario_id, titulo, valor, tipo, categoria, descricao, data,
            criado_em, sincronizado, excluido, atualizado_em
          FROM transacoes_old
        ''');
        await txn.execute('DROP TABLE transacoes_old');
      });
    }
  }

  Future<void> _createTransacoes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE transacoes (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        categoria TEXT NOT NULL,
        descricao TEXT,
        data TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        excluido INTEGER NOT NULL DEFAULT 0,
        atualizado_em TEXT NOT NULL
      )
    ''');
  }
}
