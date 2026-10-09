import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:masar/core/errors/app_exception.dart';
import 'package:masar/domain/repositories/google_account_service.dart';

/// Links Google to the current Firebase uid so existing progress is retained.
class FirebaseGoogleAccountService implements GoogleAccountService {
  FirebaseGoogleAccountService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  static Future<void>? _initialization;

  static Future<void> initializeGoogle() =>
      _initialization ??= GoogleSignIn.instance.initialize();

  @override
  bool get hasSession => _auth.currentUser != null;

  @override
  bool get isGoogleConnected =>
      _auth.currentUser?.providerData.any((provider) => provider.providerId == 'google.com') ?? false;

  @override
  Future<String?> signInWithGoogle() async {
    if (isGoogleConnected) {
      return _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? '';
    }
    try {
      await initializeGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AppException('تعذّر الدخول بحساب Google. جرّب كمان مرة.');
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final current = _auth.currentUser;
      if (current == null) {
        await _auth.signInWithCredential(credential);
      } else {
        try {
          await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (error) {
          if (error.code != 'credential-already-in-use' &&
              error.code != 'email-already-in-use') {
            rethrow;
          }
          final profile = await _db.doc('users/${current.uid}').get();
          if (profile.exists) {
            throw const AppException(
              'حساب Google مربوط بطالب ثاني. تقدّمك الحالي محفوظ؛ سجّل خروج إذا بدك تفتح الحساب الثاني.',
            );
          }
          // The temporary anonymous account has no Masar data to lose.
          await _auth.signInWithCredential(credential);
        }
      }
      return _auth.currentUser?.displayName ?? account.displayName;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw const AppException('تعذّر الدخول بحساب Google. تأكد من الاتصال وجرّب كمان مرة.');
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') {
        throw const AppException('ما في اتصال بالإنترنت. جرّب كمان مرة.');
      }
      throw const AppException('تعذّر ربط حساب Google. جرّب كمان مرة.');
    }
  }
}
