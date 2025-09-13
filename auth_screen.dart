import 'package:flutter/material.dart';
import 'package:myfin/pages/login_form.dart';
import 'package:myfin/pages/signup_form.dart';
import 'package:myfin/pages/passwordless_login_page.dart'; // Import the new page

class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentThemeMode;

  const AuthScreen({
    Key? key,
    required this.toggleTheme,
    required this.currentThemeMode,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar background
        elevation: 0,// No shadow for the AppBar
        actions: [
          IconButton(
            icon: Icon(
              widget.currentThemeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color, // Icon color adapts to theme
            ),
            onPressed: widget.toggleTheme,
          ),
          const SizedBox(width: 16), // Spacing from the right edge
        ],
      ),
      body: Center(
        // Removed the Expanded widget that was here.
        // The Center widget now directly contains the ConstrainedBox.
        child: ConstrainedBox(
          // <<< IMPORTANT CHANGE: ConstrainedBox is now direct child of Center
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // Limit the width of the whole login/signup area
          child: Column(
            // This column holds the TabBarView and the passwordless link
            crossAxisAlignment: CrossAxisAlignment
                .center, // Added to center children horizontally
            children: [
              Expanded(
                // This makes the TabBarView take all available vertical space in the Column
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // LoginForm and SignupForm now each start with a SingleChildScrollView
                    // to handle their own potential content overflow.
                    LoginForm(
                      toggleTheme: widget.toggleTheme,
                      currentThemeMode: widget.currentThemeMode,
                      tabController: _tabController,
                    ),
                    SignupForm(
                      toggleTheme: widget.toggleTheme,
                      currentThemeMode: widget.currentThemeMode,
                      tabController: _tabController,
                    ),
                  ],
                ),
              ),
              // The passwordless login button remains below the scrollable forms,
              // always visible, and is given appropriate padding.
              Padding(
                padding: const EdgeInsets.only(
                  bottom:
                      114.0, // Restored to 24.0 for better spacing and to avoid negative padding issues
                  top: 24.0,
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/passwordless_login');
                  },
                  child: Text(
                    'Or sign in with email link',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
