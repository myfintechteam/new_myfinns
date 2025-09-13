import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myfin/firebase_options.dart';
import 'package:myfin/pages/auth_gate.dart';
import 'package:myfin/pages/passwordless_login_page.dart';
import 'package:myfin/pages/profile_setup_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myfin/constants.dart';

// Your existing page imports
import 'package:myfin/pages/insurance_calculator_page.dart';
import 'package:myfin/pages/smart_spending_limits_page.dart';
import 'package:myfin/pages/investment_risk_assessment_page.dart';
import 'package:myfin/pages/loan_calculator_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFinns App',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.grey),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        cardColor: const Color.fromARGB(255, 255, 255, 255),
        shadowColor: Colors.black,
        dividerColor: Colors.black,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF5E35B1),
        scaffoldBackgroundColor: const Color(0xFF1A0033),
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A0033),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.grey),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        cardColor: const Color(0xFF2C2448),
        shadowColor: Colors.white,
        dividerColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: const Color(0xFF5E35B1), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey[300]),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) =>
            AuthGate(toggleTheme: _toggleTheme, currentThemeMode: _themeMode),
        '/home': (context) => MyFinHomePage(
          toggleTheme: _toggleTheme,
          currentThemeMode: _themeMode,
        ),
        '/insurance_calculator': (context) => const InsuranceCalculatorPage(),
        '/smart_spending_limits': (context) => const SmartSpendingLimitsPage(),
        '/loan_calculator': (context) => const LoanCalculatorPage(),
        '/investment_risk_assessment': (context) =>
            const InvestmentRiskAssessmentPage(),
        '/passwordless_login': (context) => PasswordlessLoginPage(
          toggleTheme: _toggleTheme,
          currentThemeMode: _themeMode,
        ),
        '/profile_setup': (context) => ProfileSetupPage(
          toggleTheme: _toggleTheme,
          currentThemeMode: _themeMode,
        ),
      },
    );
  }
}

class MyFinHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentThemeMode;
  const MyFinHomePage({
    super.key,
    required this.toggleTheme,
    required this.currentThemeMode,
  });
  @override
  State<MyFinHomePage> createState() => _MyFinHomePageState();
}

class _MyFinHomePageState extends State<MyFinHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _breadcrumbItems = [
    {'title': 'Dashboard', 'route': '/home'},
    {'title': 'Insurance Calculator', 'route': '/insurance_calculator'},
    {'title': 'Smart Spending Limits', 'route': '/smart_spending_limits'},
    {'title': 'Loan Calculator', 'route': '/loan_calculator'},
    {
      'title': 'Investment Risk Assessment',
      'route': '/investment_risk_assessment',
    },
  ];

  Widget _breadcrumbItem(
    BuildContext context,
    String title,
    String route, {
    bool isLast = false,
  }) {
    final bool isCurrentRoute = ModalRoute.of(context)?.settings.name == route;
    final textColor = isCurrentRoute
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyMedium?.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerLeft,
          ),
          onPressed: isCurrentRoute
              ? null
              : () {
                  Navigator.pushNamed(context, route);
                },
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isCurrentRoute ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
        if (!isLast)
          Icon(
            Icons.chevron_right,
            size: 18,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool highlighted = false,
  }) {
    return Container(
      color: highlighted
          ? Theme.of(context).primaryColor.withOpacity(0.12)
          : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        title: Text(
          title,
          style: TextStyle(
            color: highlighted
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // UPDATED: A new function to display the profile dialog.
  void _showProfileDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, a1, a2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: a1,
          curve: Curves.easeOut,
        );
        return Transform.scale(
          scale: curvedAnimation.value,
          child: Opacity(opacity: curvedAnimation.value, child: child),
        );
      },
      pageBuilder: (context, a1, a2) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(
              top:
                  MediaQuery.of(context).padding.top +
                  80, // Adjust to be below the app bar
              right: 20,
            ),
            child: ProfileDialog(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: isSmallScreen ? 56 : 80,
        leading: !isDesktop
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpeg',
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_balance, size: 80),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MyFin',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  'Professional Financial Planning',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Image.network(
                'https://placehold.co/28/6A5ACD/FFFFFF?text=B',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.account_balance, size: 22),
              ),
              const SizedBox(width: 8),
              Text(
                "INDBIN FINTECH SERVICES LLP",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: Icon(
              widget.currentThemeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: widget.toggleTheme,
          ),
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.person,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () => _showProfileDialog(context),
            ),
          const SizedBox(width: 16),
        ],
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: Theme.of(context).cardColor,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.network(
                          'https://placehold.co/60x60/FFFFFF/000000?text=MF',
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 40,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MyFin Dashboard',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  _buildDrawerItem(context, Icons.dashboard, 'Dashboard', () {
                    Navigator.pop(context);
                  }, highlighted: true),
                  _buildDrawerItem(
                    context,
                    Icons.calculate,
                    'Insurance Calculator',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/insurance_calculator');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.money_off,
                    'Smart Spending Limits',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/smart_spending_limits');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.payments,
                    'Loan Calculator',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/loan_calculator');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.bar_chart,
                    'Investment Risk Assessment',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/investment_risk_assessment',
                      );
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(context, Icons.settings, 'Settings', () {
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(context, Icons.info_outline, 'About', () {
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(context, Icons.logout, 'Logout', () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                  }),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          if (isDesktop)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.04),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: _breadcrumbItems.map((item) {
                  final int index = _breadcrumbItems.indexOf(item);
                  return _breadcrumbItem(
                    context,
                    item['title'] as String,
                    item['route'] as String,
                    isLast: index == _breadcrumbItems.length - 1,
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: Theme.of(context).brightness == Brightness.light
                      ? [
                          const Color(0xFF0288D1),
                          const Color(0xFFB3E5FC),
                          const Color(0xFF81D4FA),
                        ]
                      : [
                          const Color(0xFF1A002F),
                          const Color(0xFF2C2448),
                          const Color(0xFF6966A7),
                        ],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Professional Financial Planning Platform ⭐⭐⭐⭐⭐',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to MyFin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 32 : 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            height: 1.5,
                          ),
                          children: <TextSpan>[
                            const TextSpan(
                              text:
                                  'Your comprehensive financial planning companion ',
                            ),
                            TextSpan(
                              text: 'powered',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' by advanced algorithms and and professional expertise',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            Text(
                              'Powered by INDBIN FINTECH SERVICES LLP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            Text(
                              'Trusted by 50,000+ users',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 950),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount;
                              double aspectRatio;
                              if (constraints.maxWidth > 900) {
                                crossAxisCount = 4;
                                aspectRatio = 1.0;
                              } else if (constraints.maxWidth > 500) {
                                crossAxisCount = 3;
                                aspectRatio = 0.95;
                              } else {
                                crossAxisCount = 2;
                                aspectRatio = 0.9;
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 8.0,
                                      mainAxisSpacing: 8.0,
                                      childAspectRatio: aspectRatio,
                                    ),
                                itemCount: 4,
                                itemBuilder: (context, index) {
                                  final List<Map<String, dynamic>> features = [
                                    {
                                      'icon': Icons.analytics,
                                      'title': 'Professional Analytics',
                                      'subtitle': 'Advanced financial modeling',
                                      'color': Colors.purple[100],
                                    },
                                    {
                                      'icon': Icons.currency_exchange,
                                      'title': 'Multi-Currency Support',
                                      'subtitle': 'Global financial planning',
                                      'color': Colors.blue[100],
                                    },
                                    {
                                      'icon': Icons.track_changes,
                                      'title': 'Goal-Based Planning',
                                      'subtitle':
                                          'Achieve your financial targets',
                                      'color': Colors.orange[100],
                                    },
                                    {
                                      'icon': Icons.lightbulb,
                                      'title': 'AI-Powered Insights',
                                      'subtitle': 'Smart recommendations',
                                      'color': Colors.green[100],
                                    },
                                  ];
                                  final feature = features[index];
                                  return FeatureCard(
                                    icon: feature['icon'] as IconData,
                                    title: feature['title'] as String,
                                    subtitle: feature['subtitle'] as String,
                                    backgroundColor: feature['color'] as Color,
                                    isSmallScreen: crossAxisCount <= 2,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ProfessionalToolsSection(),

                      const FinancialHealthDashboardSection(),
                      const AIPoweredRecommendationsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// UPDATED: A new widget for the profile pop-up
class ProfileDialog extends StatefulWidget {
  @override
  _ProfileDialogState createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  Map<String, dynamic>? _userProfile;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }
      final String uid = user.uid;

      final String host = AppConstants.backendBaseUrl;

      final response = await http.get(
        Uri.parse('$host/api/profile/$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _userProfile = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load profile. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // NEW: Navigate to the profile setup page
  void _editProfile() {
    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
      Navigator.pushNamed(context, '/profile_setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        color: Theme.of(context).cardColor,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _errorMessage != null
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Email at the top
                    Text(
                      _userProfile!['email_id'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Divider(height: 20),
                    // Profile photo
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        (_userProfile!['first_name'] as String? ?? 'U')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hi, ${_userProfile!['first_name']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _editProfile,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ), // Add some space between buttons
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     onPressed: _editProfile,
                    //     icon: const Icon(Icons.edit_outlined),
                    //     label: const Text('Edit Profile'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                    //       side: BorderSide(color: Theme.of(context).dividerColor),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // // Logout button
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     onPressed: _logout,
                    //     icon: const Icon(Icons.logout),
                    //     label: const Text('Logout'),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.red,
                    //       foregroundColor: Colors.white,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final bool isSmallScreen;
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color;
    final double padding = isSmallScreen ? 10.0 : 16.0;
    final double containerPadding = isSmallScreen ? 8.0 : 10.0;
    final double iconSize = isSmallScreen ? 30.0 : 36.0;
    final double spaceAfterIcon = isSmallScreen ? 8.0 : 16.0;
    final double spaceAfterTitle = isSmallScreen ? 2.0 : 4.0;
    final double titleFont = isSmallScreen ? 14.0 : 16.0;
    final double subtitleFont = isSmallScreen ? 11.0 : 12.0;
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(containerPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Icon(icon, size: iconSize, color: Colors.white),
              ),
            ),
            SizedBox(height: spaceAfterIcon),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleFont,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: spaceAfterTitle),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: subtitleFont, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String accuracyOrTagline;
  final IconData icon;
  final Color iconColor;
  final Color cardColor;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accuracyOrTagline,
    required this.icon,
    required this.iconColor,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 36),
                ),
                Text(
                  accuracyOrTagline,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 24),
            FittedBox(
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Get Started', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessionalToolsSection extends StatelessWidget {
  const ProfessionalToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Text(
          'Professional Financial Tools',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Everything you need to make informed financial decisions in one place',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount;
              double childAspectRatio;
              if (constraints.maxWidth > 900) {
                crossAxisCount = 2;
                childAspectRatio = 1.6;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
                childAspectRatio = 1.5;
              } else {
                crossAxisCount = 1;
                childAspectRatio = 1.1;
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final List<Map<String, dynamic>> tools = [
                    {
                      'title': 'Insurance Calculator',
                      'subtitle':
                          'Calculate optimal insurance coverage for you and\nyour family with AI-powered recommendations',
                      'tagline': '94% Accuracy',
                      'icon': Icons.security,
                      'iconColor': Colors.white,
                      'cardColor': const Color(0xFF6A5ACD),
                      'onTap': () {
                        Navigator.pushNamed(context, '/insurance_calculator');
                      },
                    },
                    {
                      'title': 'Smart Spending Limits',
                      'subtitle':
                          'Determine safe daily and monthly\ntransaction limits with intelligent budgeting',
                      'tagline': 'Real-time Tracking',
                      'icon': Icons.credit_card,
                      'iconColor': Colors.white,
                      'cardColor': Colors.green,
                      'onTap': () {
                        Navigator.pushNamed(context, '/smart_spending_limits');
                      },
                    },
                    {
                      'title': 'Loan Calculator',
                      'subtitle':
                          'Find out how much loan you can afford\nwith comprehensive eligibility analysis',
                      'tagline': 'Multi-bank Rates',
                      'icon': Icons.account_balance,
                      'iconColor': Colors.white,
                      'cardColor': Colors.deepPurple,
                      'onTap': () {
                        Navigator.pushNamed(context, '/loan_calculator');
                      },
                    },
                    {
                      'title': 'Investment Risk Assessment',
                      'subtitle':
                          'Evaluate your risk tolerance for stocks and\nmutual funds with portfolio optimization',
                      'tagline': '20-Year Projection',
                      'icon': Icons.trending_up,
                      'iconColor': Colors.white,
                      'cardColor': Colors.orange,
                      'onTap': () {
                        Navigator.pushNamed(
                          context,
                          '/investment_risk_assessment',
                        );
                      },
                    },
                  ];
                  final tool = tools[index];
                  return ToolCard(
                    title: tool['title'] as String,
                    subtitle: tool['subtitle'] as String,
                    accuracyOrTagline: tool['tagline'] as String,
                    icon: tool['icon'] as IconData,
                    iconColor: tool['iconColor'] as Color,
                    cardColor: tool['cardColor'] as Color,
                    onTap: tool['onTap'] as VoidCallback,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class FinancialHealthDashboardSection extends StatelessWidget {
  const FinancialHealthDashboardSection({super.key});

  Widget _buildDashboardHeader(BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health Dashboard',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'Real-time Analytics',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your financial planning progress and get personalized insights for better financial decisions',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSmallScreen)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Generate Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Last updated: Today',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialScoreCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: '0',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  TextSpan(
                    text: '/100',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.trending_up, size: 18),
              label: const Text('Improving'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.0,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              'Completed 0 of 4 assessments',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard({
    required BuildContext context,
    required String title,
    required String status,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        _buildDashboardHeader(context, isSmallScreen),
        const SizedBox(height: 24),

        // FINANCIAL HEALTH SCORE CARD
        _buildFinancialScoreCard(context),
        const SizedBox(height: 24),

        // ASSESSMENT CARDS
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 1 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isSmallScreen ? 2.5 : 2.2,
          children: [
            _buildAssessmentCard(
              context: context,
              title: 'Insurance Coverage',
              status: 'Pending',
              subtitle: 'Not Set',
              icon: Icons.shield,
              iconColor: Colors.white,
              cardColor: Colors.blue.withOpacity(0.5),
            ),
            _buildAssessmentCard(
              context: context,
              title: 'Spending Control',
              status: 'Pending',
              subtitle: 'Not Set',
              icon: Icons.credit_card,
              iconColor: Colors.white,
              cardColor: Colors.green.withOpacity(0.5),
            ),
            _buildAssessmentCard(
              context: context,
              title: 'Loan Capacity',
              status: 'Pending',
              subtitle: 'Not Assessed',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.white,
              cardColor: Colors.deepPurple.withOpacity(0.5),
            ),
            _buildAssessmentCard(
              context: context,
              title: 'Investment Plan',
              status: 'Pending',
              subtitle: 'Not Planned',
              icon: Icons.trending_up,
              iconColor: Colors.white,
              cardColor: Colors.orange.withOpacity(0.5),
            ),
          ],
        ),
      ],
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final Color cardColor;
  final Color iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const RecommendationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
    required this.cardColor,
    required this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style:
                        titleStyle ??
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style:
                  subtitleStyle ??
                  TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(buttonText),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                side: BorderSide(
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AIPoweredRecommendationsSection extends StatelessWidget {
  const AIPoweredRecommendationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI-Powered Recommendations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personalized next steps to improve your financial health',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 1 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isSmallScreen ? 1.3 : 2.0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            RecommendationCard(
              icon: Icons.security,
              title: 'Complete Insurance Assessment',
              subtitle:
                  'Protect your family with adequate insurance coverage. Our DIME method calculator will help you determine the right amount.',
              buttonText: 'Start Assessment',
              onTap: () {
                Navigator.pushNamed(context, '/insurance_calculator');
              },
              cardColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF0F8FF)
                  : const Color(0xFF202A4A),
              iconColor: const Color(0xFF4682B4),
              titleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              subtitleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white70,
                fontSize: 14,
              ),
            ),
            RecommendationCard(
              icon: Icons.credit_card,
              title: 'Set Smart Spending Limits',
              subtitle:
                  'Control your expenses with intelligent daily and monthly spending limits based on your income and goals.',
              buttonText: 'Set Limits',
              onTap: () {
                Navigator.pushNamed(context, '/smart_spending_limits');
              },
              cardColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFF2A3E2A),
              iconColor: const Color(0xFF4CAF50),
              titleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              subtitleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white70,
                fontSize: 14,
              ),
            ),
            RecommendationCard(
              icon: Icons.account_balance_wallet,
              title: 'Check Loan Eligibility',
              subtitle:
                  'Understand your borrowing capacity and get pre-approved rates before taking any major loans.',
              buttonText: 'Check Eligibility',
              onTap: () {
                Navigator.pushNamed(context, '/loan_calculator');
              },
              cardColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF3E5F5)
                  : const Color(0xFF3A203A),
              iconColor: const Color(0xFF9C27B0),
              titleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              subtitleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white70,
                fontSize: 14,
              ),
            ),
            RecommendationCard(
              icon: Icons.trending_up,
              title: 'Plan Your Investments',
              subtitle:
                  'Build wealth systematically with a personalized investment strategy and SIP recommendations.',
              buttonText: 'Start Planning',
              onTap: () {
                Navigator.pushNamed(context, '/investment_risk_assessment');
              },
              cardColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFF4A3420),
              iconColor: const Color(0xFFFF9800),
              titleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              subtitleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
