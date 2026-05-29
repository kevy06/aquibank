import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:uuid/uuid.dart';


import '../data/datasources/local/transacao_local_datasource.dart';
import '../data/datasources/local/usuario_local_datasource.dart';
import '../data/datasources/remote/transacao_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/conta_repository_impl.dart';
import '../data/services/biometria_service.dart';
import '../domain/entities/movimentacao.dart';
import '../domain/entities/usuario.dart';

const _uuid = Uuid();

// ─── Foto de perfil (compartilhada entre telas) ───────────────────────────────

final fotoPerfilProvider = StateNotifierProvider<FotoPerfilNotifier, String?>(
  (_) => FotoPerfilNotifier(),
);

class FotoPerfilNotifier extends StateNotifier<String?> {
  FotoPerfilNotifier() : super(null) {
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('foto_perfil');
  }

  Future<void> definir(String path) async {
    state = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_perfil', path);
  }
}

// ─── Notificações ─────────────────────────────────────────────────────────────

class AppNotificacao {
  final String id;
  final String titulo;
  final String mensagem;
  final DateTime criadoEm;
  final bool lida;

  const AppNotificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.criadoEm,
    this.lida = false,
  });

  AppNotificacao copyWith({bool? lida}) => AppNotificacao(
    id: id,
    titulo: titulo,
    mensagem: mensagem,
    criadoEm: criadoEm,
    lida: lida ?? this.lida,
  );
}

class NotificacaoNotifier extends StateNotifier<List<AppNotificacao>> {
  NotificacaoNotifier() : super([]);

  void adicionar(AppNotificacao n) => state = [n, ...state];

  void marcarTodasLidas() =>
      state = state.map((n) => n.copyWith(lida: true)).toList();

  int get naoLidas => state.where((n) => !n.lida).length;
}

final notificacaoProvider =
    StateNotifierProvider<NotificacaoNotifier, List<AppNotificacao>>(
      (_) => NotificacaoNotifier(),
    );

// ─── Infrastructure ──────────────────────────────────────────────────────────

final transacaoDatasourceProvider = Provider<TransacaoLocalDatasource>(
  (_) => TransacaoLocalDatasource(),
);

final transacaoRemoteDatasourceProvider = Provider<TransacaoRemoteDatasource>(
  (_) => TransacaoRemoteDatasource(),
);

final usuarioLocalDatasourceProvider = Provider<UsuarioLocalDatasource>(
  (_) => UsuarioLocalDatasource(),
);

final authRepositoryProvider = Provider<AuthRepositoryImpl>(
  (ref) => AuthRepositoryImpl(ref.watch(usuarioLocalDatasourceProvider)),
);

final contaRepositoryProvider = Provider<ContaRepositoryImpl>(
  (ref) => ContaRepositoryImpl(
    local: ref.watch(transacaoDatasourceProvider),
    remote: ref.watch(transacaoRemoteDatasourceProvider),
  ),
);

final biometriaServiceProvider = Provider<BiometriaService>(
  (_) => BiometriaService(),
);

class BiometriaState {
  final String? usuarioId;
  final bool isLoading;
  final bool isAvailable;
  final bool isEnabled;
  final String? error;

  const BiometriaState({
    this.usuarioId,
    this.isLoading = true,
    this.isAvailable = false,
    this.isEnabled = false,
    this.error,
  });

  BiometriaState copyWith({
    String? usuarioId,
    bool? isLoading,
    bool? isAvailable,
    bool? isEnabled,
    String? error,
  }) =>
      BiometriaState(
        usuarioId: usuarioId ?? this.usuarioId,
        isLoading: isLoading ?? this.isLoading,
        isAvailable: isAvailable ?? this.isAvailable,
        isEnabled: isEnabled ?? this.isEnabled,
        error: error,
      );
}

class BiometriaNotifier extends StateNotifier<BiometriaState> {
  final BiometriaService _service;

  BiometriaNotifier(this._service) : super(const BiometriaState());

  String _key(String usuarioId) => 'biometria_ativa_$usuarioId';

  Future<void> carregar(String? usuarioId) async {
    if (usuarioId == null) {
      state = const BiometriaState(isLoading: false);
      return;
    }
    if (state.usuarioId == usuarioId && !state.isLoading) return;

    state = BiometriaState(usuarioId: usuarioId);
    final disponivel = await _service.estaDisponivel();
    final prefs = await SharedPreferences.getInstance();
    final ativa = prefs.getBool(_key(usuarioId)) ?? false;
    state = BiometriaState(
      usuarioId: usuarioId,
      isLoading: false,
      isAvailable: disponivel,
      isEnabled: disponivel && ativa,
    );
  }

  Future<bool> estaAtiva(String usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(usuarioId)) ?? false;
  }

  Future<bool> autenticarEntrada(String usuarioId) async {
    final ativa = await estaAtiva(usuarioId);
    if (!ativa) return false;
    return _service.autenticar();
  }

  Future<bool> ativar(String usuarioId) async {
    state = state.copyWith(usuarioId: usuarioId, isLoading: true, error: null);
    final disponivel = await _service.estaDisponivel();
    if (!disponivel) {
      state = BiometriaState(
        usuarioId: usuarioId,
        isLoading: false,
        isAvailable: false,
        isEnabled: false,
        error: 'Biometria indisponível neste aparelho.',
      );
      return false;
    }

    final autenticado = await _service.autenticar(
      motivo: 'Confirme sua biometria para ativar o login no AquiBank.',
    );
    if (!autenticado) {
      state = BiometriaState(
        usuarioId: usuarioId,
        isLoading: false,
        isAvailable: true,
        isEnabled: false,
        error: 'Não foi possível confirmar a biometria.',
      );
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(usuarioId), true);
    state = BiometriaState(
      usuarioId: usuarioId,
      isLoading: false,
      isAvailable: true,
      isEnabled: true,
    );
    return true;
  }

  Future<void> desativar(String usuarioId) async {
    state = state.copyWith(usuarioId: usuarioId, isLoading: true, error: null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(usuarioId), false);
    final disponivel = await _service.estaDisponivel();
    state = BiometriaState(
      usuarioId: usuarioId,
      isLoading: false,
      isAvailable: disponivel,
      isEnabled: false,
    );
  }
}

final biometriaProvider =
    StateNotifierProvider<BiometriaNotifier, BiometriaState>(
  (ref) => BiometriaNotifier(ref.watch(biometriaServiceProvider)),
);

// ─── Theme ───────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[index];
  }

  Future<void> definir(ThemeMode modo) async {
    state = modo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', modo.index);
  }

  void alternar() {
    final proximo =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    definir(proximo);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (_) => ThemeNotifier(),
);

// ─── Auth ─────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? usuarioId; // UUID from Supabase Auth
  final String? nomeUsuario;
  final String? emailUsuario;
  final bool pendingVerification; // waiting for OTP after signup
  final String? pendingEmail;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.usuarioId,
    this.nomeUsuario,
    this.emailUsuario,
    this.pendingVerification = false,
    this.pendingEmail,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? usuarioId,
    String? nomeUsuario,
    String? emailUsuario,
    bool? pendingVerification,
    String? pendingEmail,
    String? error,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    usuarioId: usuarioId ?? this.usuarioId,
    nomeUsuario: nomeUsuario ?? this.nomeUsuario,
    emailUsuario: emailUsuario ?? this.emailUsuario,
    pendingVerification: pendingVerification ?? this.pendingVerification,
    pendingEmail: pendingEmail ?? this.pendingEmail,
    error: error ?? this.error,
  );

  AuthState get loading => copyWith(isLoading: true, error: null);
  AuthState get clearError => copyWith(error: null);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepositoryImpl _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  Future<void> verificarSessao() async {
    state = state.loading;
    try {
      final usuario = await _repo.sessaoAtual();
      if (usuario == null) {
        state = const AuthState();
        return;
      }
      state = _fromUsuario(usuario);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<bool> login(String email, String senha) async {
    state = state.loading;
    try {
      final usuario = await _repo.login(email.trim().toLowerCase(), senha);
      if (usuario == null) {
        state = state.copyWith(isLoading: false, error: 'Credenciais inválidas.');
        return false;
      }
      state = _fromUsuario(usuario);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _traduzirErro(e.message),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao conectar ao servidor.',
      );
      return false;
    }
  }

  Future<bool> cadastrar(String nome, String email, String senha) async {
    state = state.loading;
    try {
      final usuario = await _repo.cadastrar(nome, email, senha);
      state = _fromUsuario(usuario);
      return true;
    } on EmailConfirmacaoException catch (e) {
      // Signup OK but email confirmation required — show OTP screen
      state = AuthState(pendingVerification: true, pendingEmail: e.email);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _traduzirErro(e.message));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Erro ao criar conta.');
      return false;
    }
  }

  Future<bool> verificarOTP(String email, String token) async {
    state = state.loading;
    try {
      final usuario = await _repo.verificarOTP(email, token);
      state = _fromUsuario(usuario);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _traduzirErro(e.message));
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Código inválido ou expirado. Tente novamente.',
      );
      return false;
    }
  }

  Future<void> reenviarCodigo(String email) async {
    try {
      await _repo.reenviarCodigo(email);
    } catch (_) {}
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void limparErro() => state = state.clearError;

  AuthState _fromUsuario(Usuario u) => AuthState(
    isAuthenticated: true,
    usuarioId: u.id,
    nomeUsuario: u.nome,
    emailUsuario: u.email,
  );

  String _traduzirErro(String msg) {
    if (msg.contains('Invalid login credentials')) return 'E-mail ou senha inválidos.';
    if (msg.contains('Email not confirmed')) return 'Confirme seu e-mail antes de entrar.';
    if (msg.contains('User already registered')) return 'Este e-mail já está cadastrado.';
    if (msg.contains('Password should be at least')) return 'A senha deve ter no mínimo 6 caracteres.';
    if (msg.contains('Token has expired')) return 'Código expirado. Solicite um novo.';
    if (msg.contains('OTP')) return 'Código inválido.';
    if (msg.contains('rate limit') ||
        msg.contains('over_email_send_rate_limit') ||
        msg.contains('Too Many') ||
        msg.contains('security purposes')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

// ─── Conta ────────────────────────────────────────────────────────────────────

class ContaState {
  final bool isLoading;
  final List<Movimentacao> movimentacoes;
  final String searchQuery;
  final TipoMovimentacao? tipoFiltro;
  final String? categoriaFiltro;
  final String? error;

  const ContaState({
    this.isLoading = false,
    this.movimentacoes = const [],
    this.searchQuery = '',
    this.tipoFiltro,
    this.categoriaFiltro,
    this.error,
  });

  ContaState copyWith({
    bool? isLoading,
    List<Movimentacao>? movimentacoes,
    String? searchQuery,
    TipoMovimentacao? tipoFiltro,
    bool clearTipo = false,
    String? categoriaFiltro,
    bool clearCategoria = false,
    String? error,
  }) => ContaState(
    isLoading: isLoading ?? this.isLoading,
    movimentacoes: movimentacoes ?? this.movimentacoes,
    searchQuery: searchQuery ?? this.searchQuery,
    tipoFiltro: clearTipo ? null : (tipoFiltro ?? this.tipoFiltro),
    categoriaFiltro:
        clearCategoria ? null : (categoriaFiltro ?? this.categoriaFiltro),
    error: error,
  );

  List<Movimentacao> get ordenadas {
    final lista = List<Movimentacao>.from(movimentacoes)
      ..sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  List<Movimentacao> get filtradas {
    var lista = ordenadas;
    if (tipoFiltro != null) {
      lista = lista.where((m) => m.tipo == tipoFiltro).toList();
    }
    if (categoriaFiltro != null && categoriaFiltro!.isNotEmpty) {
      lista = lista.where((m) => m.categoria == categoriaFiltro).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      lista = lista
          .where((m) =>
              m.titulo.toLowerCase().contains(q) ||
              m.categoria.toLowerCase().contains(q))
          .toList();
    }
    return lista;
  }

  double get entradas => movimentacoes
      .where((m) => m.tipo == TipoMovimentacao.entrada)
      .fold(0, (s, m) => s + m.valor);

  double get saidas => movimentacoes
      .where((m) => m.tipo == TipoMovimentacao.saida)
      .fold(0, (s, m) => s + m.valor);

  double get saldoAtual => entradas - saidas;

  List<Movimentacao> doMes(int ano, int mes) =>
      ordenadas.where((m) => m.data.year == ano && m.data.month == mes).toList();

  double entradasDoMes(int ano, int mes) => doMes(ano, mes)
      .where((m) => m.tipo == TipoMovimentacao.entrada)
      .fold(0, (s, m) => s + m.valor);

  double saidasDoMes(int ano, int mes) => doMes(ano, mes)
      .where((m) => m.tipo == TipoMovimentacao.saida)
      .fold(0, (s, m) => s + m.valor);

  double saldoDoMes(int ano, int mes) =>
      entradasDoMes(ano, mes) - saidasDoMes(ano, mes);

  List<DateTime> get mesesDisponiveis {
    final mapa = <String, DateTime>{};
    for (final m in movimentacoes) {
      final chave =
          '${m.data.year}-${m.data.month.toString().padLeft(2, '0')}';
      mapa[chave] = DateTime(m.data.year, m.data.month);
    }
    return mapa.values.toList()..sort((a, b) => b.compareTo(a));
  }

  Map<String, double> categoriasDoMes(
      int ano, int mes, TipoMovimentacao tipo) {
    final mapa = <String, double>{};
    for (final m in doMes(ano, mes)) {
      if (m.tipo == tipo) mapa[m.categoria] = (mapa[m.categoria] ?? 0) + m.valor;
    }
    return mapa;
  }

  Map<int, double> totaisDiariosDoMes(int ano, int mes, TipoMovimentacao tipo) {
    final mapa = <int, double>{};
    for (final m in doMes(ano, mes)) {
      if (m.tipo == tipo) {
        mapa[m.data.day] = (mapa[m.data.day] ?? 0) + m.valor;
      }
    }
    return mapa;
  }
}

class ContaNotifier extends StateNotifier<ContaState> {
  final ContaRepositoryImpl _repo;

  ContaNotifier(this._repo) : super(const ContaState());

  Future<void> carregar(String usuarioId) async {
    state = state.copyWith(isLoading: true);
    try {
      final lista = await _repo.listar(usuarioId);
      state = state.copyWith(isLoading: false, movimentacoes: lista);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> adicionar({
    required String usuarioId,
    required String titulo,
    required double valor,
    required TipoMovimentacao tipo,
    required String categoria,
    String? descricao,
    DateTime? data,
  }) async {
    final mov = Movimentacao(
      id: _uuid.v4(),
      usuarioId: usuarioId,
      titulo: titulo.trim(),
      valor: valor,
      tipo: tipo,
      categoria: categoria,
      descricao: descricao?.trim(),
      data: data ?? DateTime.now(),
      criadoEm: DateTime.now(),
    );
    await _repo.inserir(mov);
    state = state.copyWith(movimentacoes: [...state.movimentacoes, mov]);
  }

  Future<void> editar(Movimentacao mov) async {
    await _repo.atualizar(mov);
    final lista =
        state.movimentacoes.map((m) => m.id == mov.id ? mov : m).toList();
    state = state.copyWith(movimentacoes: lista);
  }

  Future<void> excluir(String id) async {
    await _repo.excluir(id);
    state = state.copyWith(
      movimentacoes: state.movimentacoes.where((m) => m.id != id).toList(),
    );
  }

  void buscar(String query) => state = state.copyWith(searchQuery: query);

  void filtrarTipo(TipoMovimentacao? tipo) => tipo == null
      ? state = state.copyWith(clearTipo: true)
      : state = state.copyWith(tipoFiltro: tipo);

  void filtrarCategoria(String? cat) => cat == null
      ? state = state.copyWith(clearCategoria: true)
      : state = state.copyWith(categoriaFiltro: cat);

  void limparFiltros() => state = state.copyWith(
    searchQuery: '',
    clearTipo: true,
    clearCategoria: true,
  );

  void limpar() => state = const ContaState();

  Future<void> limparTudo(String usuarioId) async {
    await _repo.excluirTodos(usuarioId);
    state = const ContaState();
  }
}

final contaProvider = StateNotifierProvider<ContaNotifier, ContaState>(
  (ref) => ContaNotifier(ref.watch(contaRepositoryProvider)),
);
