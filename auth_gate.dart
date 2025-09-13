import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfin/main.dart';
import 'package:myfin/pages/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:cloud_firestore/cloud_firestore.dart'; // REMOVED THIS IMPORT
import 'package:myfin/pages/profile_setup_page.dart';
import 'package:http/http.dart'
    as http; // NEW: Import http for network requests
import 'dart:convert'; // NEW: For JSON encoding/decoding
import 'package:myfin/constants.dart';

class AuthGate extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentThemeMode;

  const AuthGate({
    Key? key,
    required this.toggleTheme,
    required this.currentThemeMode,
  }) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // // Define your backend API URL
  // // IMPORTANT: Replace 3000 with the actual port your Node.js backend is running on
  // final String _backendBaseUrl = 'http://localhost:3000';
  final String _backendBaseUrl = AppConstants.backendBaseUrl;
  @override
  void initState() {
    super.initState();
    _initAuthLinkHandling();
  }

  Future<void> _initAuthLinkHandling() async {
    if (kIsWeb) {
      final Uri currentUri = Uri.base;
      if (currentUri.toString().contains('/#/auth')) {
        _handleSignInLink(currentUri);
      }
    } else {
      // For non-web platforms (Android, iOS), if you want dynamic links,
      // you'll need to re-add firebase_dynamic_links to pubspec.yaml
      // and uncomment this section.
      /*
      final PendingDynamicLinkData? initialLink =
          await FirebaseDynamicLinks.instance.getInitialLink();

      if (initialLink != null) {
        _handleSignInLink(initialLink.link);
      }

      FirebaseDynamicLinks.instance.onLink.listen(
        (PendingDynamicLinkData? dynamicLink) {
          if (dynamicLink != null) {
            _handleSignInLink(dynamicLink.link);
          }
        },
        onError: (e) {
          _showSnackBar(
              'Failed to receive dynamic link: ${e.message}', Colors.red);
        },
      );
      */
    }
  }

  Future<void> _handleSignInLink(Uri deepLink) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('emailForSignIn');

    if (auth.isSignInWithEmailLink(deepLink.toString())) {
      if (email == null) {
        _showSnackBar(
          'Please re-enter your email to complete sign-in.',
          Colors.orange,
        );
        return;
      }

      try {
        await auth.signInWithEmailLink(
          email: email,
          emailLink: deepLink.toString(),
        );
        await prefs.remove('emailForSignIn');
        _showSnackBar('Successfully signed in!', Colors.green);
        // AuthGate's StreamBuilder will automatically rebuild and handle navigation.
      } on FirebaseAuthException catch (e) {
        _showSnackBar('Error signing in with link: ${e.message}', Colors.red);
        await prefs.remove('emailForSignIn');
      } catch (e) {
        _showSnackBar(
          'An unexpected error occurred during sign-in: ${e.toString()}',
          Colors.red,
        );
        await prefs.remove('emailForSignIn');
      }
    }
  }

  // NEW: Function to check profile completion from backend
  Future<bool> _checkProfileCompletion(String firebaseUid) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/api/profile/$firebaseUid'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['setup_complete'] ==
            true; // Check the 'setup_complete' field from PostgreSQL
      } else if (response.statusCode == 404) {
        // Profile not found, so setup is not complete
        return false;
      } else {
        // Handle other HTTP errors
        print(
          'Failed to load profile from backend: ${response.statusCode} ${response.body}',
        );
        _showSnackBar(
          'Failed to load profile status. Please try again.',
          Colors.red,
        );
        return false; // Assume not complete on error
      }
    } catch (e) {
      print('Error connecting to backend: $e');
      _showSnackBar(
        'Could not connect to backend server. Please ensure it is running.',
        Colors.red,
      );
      return false; // Assume not complete on connection error
    }
  }

  void _showSnackBar(String message, Color color) {
    if (_scaffoldMessengerKey.currentState != null) {
      _scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is NOT signed in
          if (!snapshot.hasData) {
            return AuthScreen(
              toggleTheme: widget.toggleTheme,
              currentThemeMode: widget.currentThemeMode,
            );
          }

          // User IS signed in, now check profile setup status
          final User user = snapshot.data!;
          return FutureBuilder<bool>(
            // Changed FutureBuilder type to bool
            future: _checkProfileCompletion(
              user.uid,
            ), // Call new backend check function
            builder: (context, profileCompletionSnapshot) {
              // Show a loading indicator while fetching profile completion status
              if (profileCompletionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                );
              }

              // Handle errors during profile check (e.g., backend down)
              if (profileCompletionSnapshot.hasError) {
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Center(
                    child: Text(
                      'Error checking profile status: ${profileCompletionSnapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Profile completion status is available
              final bool setupComplete =
                  profileCompletionSnapshot.data ??
                  false; // Default to false if null

              if (setupComplete) {
                // Profile is complete, redirect to home page
                return MyFinHomePage(
                  toggleTheme: widget.toggleTheme,
                  currentThemeMode: widget.currentThemeMode,
                );
              } else {
                // Profile is not complete or doesn't exist, redirect to profile setup
                return ProfileSetupPage(
                  toggleTheme: widget.toggleTheme,
                  currentThemeMode: widget.currentThemeMode,
                );
              }
            },
          );
        },
      ),
    );
  }
}
