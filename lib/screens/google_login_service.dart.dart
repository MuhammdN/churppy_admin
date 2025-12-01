import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  // -----------------------------------------------------------
  // ✅ GOOGLE LOGIN → RETURNS USER DATA MAP
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>?> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            "445644172348-5r06fmdbhih3furf3s81mu9kcolq94im.apps.googleusercontent.com",
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google sign-in cancelled');
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final data = {
        'provider': 'google',
        'provider_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? "",
        
        // 🔥 IMPORTANT FIX → backend expects "photo", not "image"
        'photo': googleUser.photoUrl ?? "",
        
        'id_token': googleAuth.idToken ?? "",
        'access_token': googleAuth.accessToken ?? "",
      };

      debugPrint('✅ GOOGLE LOGIN DATA:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));

      return data;
    } catch (e) {
      debugPrint('🔥 Google login error: $e');
      return null;
    }
  }

  // -----------------------------------------------------------
  // ✅ APPLE LOGIN → RETURNS USER DATA MAP
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>?> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final fullName =
          "${credential.givenName ?? ''} ${credential.familyName ?? ''}".trim();

      final data = {
        'provider': 'apple',
        'provider_id': credential.userIdentifier ?? "",
        'email': credential.email ?? "",
        'name': fullName,

        // 🔥 Apple returns no image, backend expects photo key
        'photo': "",

        'id_token': credential.identityToken ?? "",
      };

      debugPrint('✅ APPLE LOGIN DATA:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));

      return data;
    } catch (e) {
      debugPrint('🔥 Apple login error: $e');
      return null;
    }
  }
}
