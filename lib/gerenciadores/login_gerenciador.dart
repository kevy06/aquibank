import 'package:flutter/material.dart';

import '../modelos/usuario.dart';

class LoginGerenciador extends ChangeNotifier {
  bool _modoLogin = true;
  bool get modoLogin => _modoLogin;

  final campoNome = TextEditingController();
  final campoEmail = TextEditingController();
  final campoSenha = TextEditingController();

  String? _mensagemErro;
  String? get mensagemErro => _mensagemErro;

  Usuario? _usuarioAtual;

  void alternarModo() {
    _modoLogin = !_modoLogin;
    _mensagemErro = null;
    notifyListeners();
  }

  bool validarEEntrar() {
    _mensagemErro = null;
    final email = campoEmail.text.trim();
    final senha = campoSenha.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _mensagemErro = 'Preencha e-mail e senha.';
      notifyListeners();
      return false;
    }

    if (_modoLogin) {
      if (_usuarioAtual == null) {
        _mensagemErro = 'Conta não encontrada. Cadastre-se primeiro.';
        notifyListeners();
        return false;
      }
      if (_usuarioAtual!.email != email || _usuarioAtual!.senha != senha) {
        _mensagemErro = 'Credenciais inválidas.';
        notifyListeners();
        return false;
      }
      return true;
    }

    final nome = campoNome.text.trim();
    if (nome.isEmpty) {
      _mensagemErro = 'Informe seu nome.';
      notifyListeners();
      return false;
    }

    _usuarioAtual = Usuario(nome: nome, email: email, senha: senha);
    _modoLogin = true;
    notifyListeners();
    return true;
  }

  String get nomeUsuario => _usuarioAtual?.nome ?? 'Usuário';

  @override
  void dispose() {
    campoNome.dispose();
    campoEmail.dispose();
    campoSenha.dispose();
    super.dispose();
  }
}
