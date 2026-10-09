/// Account authentication stays separate from the learning repository.
/// A null result means the student dismissed Google's account picker.
abstract class GoogleAccountService {
  bool get hasSession;
  bool get isGoogleConnected;
  Future<String?> signInWithGoogle();
}
