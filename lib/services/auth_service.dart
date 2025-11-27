import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Service class to handle Firebase Authentication operations
/// Supports Google Sign-In, Facebook Sign-In, and Phone OTP authentication
class AuthService {
  // Firebase Auth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize Google Sign-In (should be called once at app startup)
  static Future<void> initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      print('Google Sign-In initialization error: $e');
    }
  }

  /// Sign in with Google
  /// Returns UserCredential on success, throws Exception on failure
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Initialize if not already done
      await initializeGoogleSignIn();
      
      // Authenticate with Google
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      
      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential (only idToken is available in v7.x)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign in with Facebook
  /// Returns UserCredential on success, throws Exception on failure
  static Future<UserCredential> signInWithFacebook() async {
    try {
      // Trigger the Facebook Sign-In flow
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['public_profile'], // Removed 'email' to avoid invalid scopes error
      );

      // Check if login was successful
      if (loginResult.status != LoginStatus.success) {
        throw Exception('Facebook sign-in failed: ${loginResult.status}');
      }

      // Get the access token
      final AccessToken? accessToken = loginResult.accessToken;
      
      if (accessToken == null) {
        throw Exception('Facebook access token is null');
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential = 
          FacebookAuthProvider.credential(accessToken.tokenString);

      // Sign in to Firebase with the Facebook credential
      return await _auth.signInWithCredential(facebookAuthCredential);
    } catch (e) {
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  /// Send OTP to phone number
  /// [phoneNumber] should include country code (e.g., +84 for Vietnam)
  /// 
  /// Callbacks:
  /// - [onCodeSent] called when OTP is sent successfully with verificationId and resendToken
  /// - [onVerificationCompleted] called when auto-verification succeeds
  /// - [onVerificationFailed] called when verification fails
  /// - [onCodeAutoRetrievalTimeout] called when auto-retrieval timeout occurs
  static Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        
        // Called when SMS code is automatically retrieved (Android only)
        verificationCompleted: onVerificationCompleted,
        
        // Called when verification fails
        verificationFailed: onVerificationFailed,
        
        // Called when OTP is sent successfully
        codeSent: onCodeSent,
        
        // Called when auto-retrieval timeout
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP code
  /// [verificationId] is received from onCodeSent callback
  /// [smsCode] is the 6-digit code entered by user
  /// Returns UserCredential on success
  static Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      // Create a PhoneAuthCredential with the code
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  /// Sign out from Firebase and all social providers
  static Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      
      // Sign out from Google - Using attemptLightweightAuthentication to check
      try {
        final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
        if (account != null) {
          await GoogleSignIn.instance.signOut();
        }
      } catch (e) {
        // Ignore if not signed in
        print('Google sign out skipped: $e');
      }
      
      // Sign out from Facebook
      await FacebookAuth.instance.logOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current user details as a Map
  /// Returns null if no user is signed in
  static Map<String, dynamic>? getCurrentUserDetails() {
    final user = currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'isEmailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
    };
  }

  /// Check if a user is currently signed in
  static bool isUserSignedIn() {
    return currentUser != null;
  }
}
