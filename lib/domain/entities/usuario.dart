class Usuario {
  final String? id; // UUID from Supabase Auth
  final String nome;
  final String email;
  final DateTime criadoEm;

  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.criadoEm,
  });

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    DateTime? criadoEm,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome': nome,
    'email': email,
    'created_at': criadoEm.toIso8601String(),
  };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
    id: map['id'] as String?,
    nome: map['nome'] as String,
    email: map['email'] as String,
    criadoEm: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : DateTime.now(),
  );
}
