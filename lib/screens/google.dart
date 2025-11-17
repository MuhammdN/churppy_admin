import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();

      if (account == null) return null;

      return {
        "name": account.displayName,
        "email": account.email,
        "image": account.photoUrl,
        "provider": "google",
        "provider_id": account.id,
      };

    } catch (e) {
      print("Google Login Error: $e");
      return null;
    }
  }
}
