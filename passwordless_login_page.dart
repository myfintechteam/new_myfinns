import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
// import 'package:myfin/constants.dart';

class PasswordlessLoginPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentThemeMode;

  const PasswordlessLoginPage({
    Key? key,
    required this.toggleTheme,
    required this.currentThemeMode,
  }) : super(key: key);

  @override
  State<PasswordlessLoginPage> createState() => _PasswordlessLoginPageState();
}

class _PasswordlessLoginPageState extends State<PasswordlessLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // IMPORTANT: Replace 'XXXX' with the actual port number your Flutter web app runs on.
  // When you run 'flutter run -d web', the console will show you the URL, e.g., 'http://localhost:5000/'.
  // Use that port number here.
  final String _appAuthLink =
      'http://localhost:53827/#/auth'; // <<< SET YOUR ACTUAL WEB PORT HERE!

  Future<void> _sendSignInLink() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Construct the ActionCodeSettings object
      final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: _appAuthLink, // The deep link for your app to handle
        handleCodeInApp: true, // Must be true for email link sign-in
        // Commenting out Android and iOS settings as requested for web-only local setup
        // android: AndroidPackageSettings(
        //   packageName: 'com.example.myfin', // Your actual Android package name
        //   installApp: true,
        //   minimumVersion: '1',
        // ),
        // iOS: iOSBundleID('com.example.myfin'), // Your actual iOS bundle ID
      );

      try {
        await FirebaseAuth.instance.sendSignInLinkToEmail(
          email: _emailController.text.trim(),
          actionCodeSettings: actionCodeSettings,
        );

        // Save the email locally so you don't need to ask the user for it again
        // if they open the link on the same device.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emailForSignIn', _emailController.text.trim());

        _showSnackBar(
          'A sign-in link has been sent to ${_emailController.text.trim()}. Check your inbox!',
          Colors.green,
        );
      } on FirebaseAuthException catch (e) {
        _showSnackBar('Error sending link: ${e.message}', Colors.red);
      } catch (e) {
        _showSnackBar(
          'An unexpected error occurred: ${e.toString()}',
          Colors.red,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign In with Email Link',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Receive a Magic Link to Log In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email address to receive a one-time sign-in link. No password needed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _sendSignInLink,
                          child: const Text('Send Sign-in Link'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
