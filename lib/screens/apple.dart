import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.fullName,
          AppleIDAuthorizationScopes.email,
        ],
      );

      return {
        "name": "${credential.givenName ?? ''} ${credential.familyName ?? ''}",
        "email": credential.email ?? '',
        "provider": "apple",
        "provider_id": credential.userIdentifier,
      };

    } catch (e) {
      print("Apple Login Error: $e");
      return null;
    }
  }
}
