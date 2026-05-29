import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometriaService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> estaDisponivel() async {
    if (kIsWeb) return false;

    try {
      final suporte = await _auth.isDeviceSupported();
      if (!suporte) return false;

      final biometrias = await _auth.getAvailableBiometrics();
      return biometrias.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> autenticar({String motivo = 'Confirme sua biometria para entrar no AquiBank.'}) async {
    if (!await estaDisponivel()) return false;

    try {
      return _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
