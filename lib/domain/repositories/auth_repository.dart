import '../entities/usuario.dart';

abstract class AuthRepository {
  Future<Usuario?> login(String email, String senha);
  Future<Usuario> cadastrar(String nome, String email, String senha);
  Future<Usuario?> sessaoAtual();
  Future<void> logout();
}
