import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/local/usuario_local_datasource.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';

// Thrown when signup succeeds but email confirmation is still pending
class EmailConfirmacaoException implements Exception {
  final String email;
  const EmailConfirmacaoException(this.email);
}

class AuthRepositoryImpl implements AuthRepository {
  final UsuarioLocalDatasource _local;

  const AuthRepositoryImpl(this._local);

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Usuario?> login(String email, String senha) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: senha,
    );
    if (response.user == null) return null;
    final usuario = await _fetchPerfil(response.user!.id, email.trim().toLowerCase());
    if (usuario != null) await _salvarLocalmente(usuario);
    return usuario;
  }

  @override
  Future<Usuario> cadastrar(String nome, String email, String senha) async {
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: senha,
      data: {'nome': nome.trim()},
    );
    if (response.user == null) throw Exception('Erro ao criar conta.');

    // Session is null when email confirmation is required
    if (response.session == null) {
      throw EmailConfirmacaoException(email.trim().toLowerCase());
    }

    final usuario = Usuario(
      id: response.user!.id,
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      criadoEm: DateTime.now(),
    );
    await _salvarLocalmente(usuario);
    return usuario;
  }

  Future<Usuario> verificarOTP(String email, String token) async {
    final response = await _client.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: token.trim(),
      type: OtpType.signup,
    );
    if (response.user == null) throw Exception('Código inválido ou expirado.');
    final usuario = await _fetchPerfil(response.user!.id, email.trim().toLowerCase()) ??
        Usuario(
          id: response.user!.id,
          nome: email.split('@').first,
          email: email.trim().toLowerCase(),
          criadoEm: DateTime.now(),
        );
    await _salvarLocalmente(usuario);
    return usuario;
  }

  Future<void> reenviarCodigo(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
    );
  }

  @override
  Future<Usuario?> sessaoAtual() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final usuario = await _fetchPerfil(user.id, user.email ?? '');
      if (usuario != null) await _salvarLocalmente(usuario);
      return usuario;
    } catch (_) {
      return _local.buscarPorId(user.id);
    }
  }

  @override
  Future<void> logout() => _client.auth.signOut();

  Future<void> _salvarLocalmente(Usuario usuario) async {
    try {
      await _local.salvar(usuario);
    } catch (_) {}
  }

  Future<Usuario?> _fetchPerfil(String id, String email) async {
    try {
      final data = await _client
          .from('profiles')
          .select('nome, created_at')
          .eq('id', id)
          .single();
      return Usuario(
        id: id,
        nome: data['nome'] as String? ?? email.split('@').first,
        email: email,
        criadoEm: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
      );
    } catch (_) {
      return Usuario(
        id: id,
        nome: email.split('@').first,
        email: email,
        criadoEm: DateTime.now(),
      );
    }
  }
}
