# AquiBank - Controle Financeiro Digital

Aplicativo de controle financeiro pessoal construído com Flutter e arquitetura MVVM.

## Organização (MVVM)

```
lib/
├── main.dart
├── modelos/
│   ├── movimentacao.dart
│   └── usuario.dart
├── gerenciadores/
│   ├── login_gerenciador.dart
│   └── conta_gerenciador.dart
└── telas/
    ├── tela_login.dart
    ├── tela_home.dart
    └── tela_relatorio.dart
```

## Executar

```bash
flutter pub get
flutter run -d chrome
```
