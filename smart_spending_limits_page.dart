import 'package:flutter/material.dart';
import 'dart:math'; // For CustomPainter and calculations
import 'package:firebase_auth/firebase_auth.dart'; // For logout functionality

class SmartSpendingLimitsPage extends StatefulWidget {
  const SmartSpendingLimitsPage({super.key});
  @override
  State<SmartSpendingLimitsPage> createState() =>
      _SmartSpendingLimitsPageState();
}

class _SmartSpendingLimitsPageState extends State<SmartSpendingLimitsPage> {
  int _currentStep = 1; // Step 1 for inputs, Step 2 for analytics

  // --- Breadcrumb Items for this page ---
  final List<Map<String, dynamic>> _breadcrumbItems = [
    {'title': 'Dashboard', 'route': '/home'},
    {'title': 'Smart Spending Limits', 'route': '/smart_spending_limits'},
  ];

  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  final TextEditingController _fixedMonthlyExpensesController =
      TextEditingController();
  final TextEditingController _monthlySavingsGoalController =
      TextEditingController();
  final TextEditingController _currentEmergencyFundController =
      TextEditingController();
  final TextEditingController _numDependentsController =
      TextEditingController();
  final TextEditingController _currentMonthlyDebtPaymentsController =
      TextEditingController();

  String? _riskTolerance;
  String? _lifestyle;
  double _dailySpendingLimit = 0.0;
  double _monthlySpendingLimit = 0.0;

  // --- Analytics State ---
  Map<String, double> _spendingAllocationData = {};
  String _spendingRecommendationMessage = '';

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _fixedMonthlyExpensesController.dispose();
    _monthlySavingsGoalController.dispose();
    _currentEmergencyFundController.dispose();
    _numDependentsController.dispose();
    _currentMonthlyDebtPaymentsController.dispose();
    super.dispose();
  }

  // NEW: Validation for current step
  bool _isCurrentStepValid() {
    // For input step
    if (_currentStep == 1) {
      return _monthlyIncomeController.text.isNotEmpty &&
          _fixedMonthlyExpensesController.text.isNotEmpty &&
          _monthlySavingsGoalController.text.isNotEmpty &&
          _currentMonthlyDebtPaymentsController.text.isNotEmpty &&
          _riskTolerance != null &&
          _riskTolerance!.isNotEmpty &&
          _lifestyle != null &&
          _lifestyle!.isNotEmpty;
    }
    // For analytics step, it's always valid to view
    return true;
  }

  void _nextStep() {
    if (!_isCurrentStepValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      if (_currentStep == 1) {
        _calculateLimits(); // Calculate before moving to analytics
        _currentStep++;
      } else if (_currentStep == 2) {
        _currentStep = 1; // Reset to start after viewing analytics
        _resetForm();
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
    });
  }

  void _resetForm() {
    _monthlyIncomeController.clear();
    _fixedMonthlyExpensesController.clear();
    _monthlySavingsGoalController.clear();
    _currentEmergencyFundController.clear();
    _numDependentsController.clear();
    _currentMonthlyDebtPaymentsController.clear();
    _riskTolerance = null;
    _lifestyle = null;
    _dailySpendingLimit = 0.0;
    _monthlySpendingLimit = 0.0;
    _spendingAllocationData = {};
    _spendingRecommendationMessage = '';
  }

  void _calculateLimits() {
    double monthlyIncome =
        double.tryParse(_monthlyIncomeController.text) ?? 0.0;
    double fixedExpenses =
        double.tryParse(_fixedMonthlyExpensesController.text) ?? 0.0;
    double savingsGoal =
        double.tryParse(_monthlySavingsGoalController.text) ?? 0.0;
    double debtPayments =
        double.tryParse(_currentMonthlyDebtPaymentsController.text) ?? 0.0;

    // Ensure disposable income doesn't go negative before applying factors
    double baseDisposableIncome =
        monthlyIncome - fixedExpenses - savingsGoal - debtPayments;
    if (baseDisposableIncome < 0) {
      baseDisposableIncome = 0; // Cannot have negative disposable income
    }

    double riskFactor = 1.0;
    if (_riskTolerance == 'Conservative - Prefer safety over flexibility') {
      riskFactor = 0.8;
    } else if (_riskTolerance ==
        'Aggressive - Willing to spend more for goals') {
      riskFactor = 1.2;
    }

    double lifestyleFactor = 1.0;
    if (_lifestyle == 'Minimal - Basic needs focused') {
      lifestyleFactor = 0.9;
    } else if (_lifestyle == 'Comfortable - Some luxuries') {
      lifestyleFactor = 1.1;
    } else if (_lifestyle == 'Luxurious - Premium lifestyle') {
      lifestyleFactor = 1.2;
    }

    double adjustedFlexibleSpending =
        baseDisposableIncome * riskFactor * lifestyleFactor;

    setState(() {
      _monthlySpendingLimit = adjustedFlexibleSpending > 0
          ? adjustedFlexibleSpending
          : 0.0;
      _dailySpendingLimit = _monthlySpendingLimit / 30.0;

      // --- Analytics Calculation for Pie Chart ---
      // What's left for flexible spending after fixed, savings, and debts
      double currentFlexibleSpending =
          monthlyIncome - fixedExpenses - savingsGoal - debtPayments;
      if (currentFlexibleSpending < 0) currentFlexibleSpending = 0;

      // Suggest a portion of flexible spending for insurance/investments
      double recommendedInvestmentAmount =
          currentFlexibleSpending * 0.15; // Example: 15% of flexible spending
      if (recommendedInvestmentAmount < 0)
        recommendedInvestmentAmount = 0; // Ensure non-negative

      // Adjust current flexible spending to reflect the recommended reallocation
      double remainingFlexibleSpending =
          currentFlexibleSpending - recommendedInvestmentAmount;
      if (remainingFlexibleSpending < 0)
        remainingFlexibleSpending = 0; // Ensure non-negative

      _spendingAllocationData = {
        'Fixed Expenses': fixedExpenses,
        'Savings Goal': savingsGoal,
        'Debt Payments': debtPayments,
        'Current Flexible Spending': remainingFlexibleSpending,
        'Recommended Investments/Insurance': recommendedInvestmentAmount,
      };

      // Generate recommendation message
      if (recommendedInvestmentAmount > 0) {
        _spendingRecommendationMessage =
            'You have ₹${recommendedInvestmentAmount.toStringAsFixed(0)} available monthly for additional investments or insurance. Reallocating this can significantly boost your long-term savings and security.';
      } else {
        _spendingRecommendationMessage =
            'Currently, your disposable income is tight. Focus on reducing debts or increasing income before allocating more to new investments/insurance.';
      }
    });
  }

  // --- Helper for Breadcrumb Item ---
  Widget _buildBreadcrumbItem(
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: isMobile ? 56 : 80, // Match main.dart toolbarHeight
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            // App Logo
            Image.asset(
              'assets/images/logo.jpeg', // <--- Your image asset path
              height: 40, // You might need to specify height/width
              width: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_balance, size: 80),
            ),
            const SizedBox(width: 8),
            // App Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MyFinns',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  'Professional Financial Planning',
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Company Branding
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
          // Theme Toggle
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              // This page doesn't have direct access to toggleTheme, it's passed from MyApp
              // For a standalone page, you might need to use a Provider or inherited widget
              // For demonstration, I'll use a placeholder action.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Theme toggle not directly available on this page.',
                  ),
                ),
              );
            },
          ),
          // Logout Button for Desktop
          if (isDesktop)
            TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).iconTheme.color,
              ),
              label: Text(
                'Logout',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
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
      body: Column(
        // Main Column for the body content
        children: [
          if (isDesktop) // Breadcrumbs only for desktop
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
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
                  return _buildBreadcrumbItem(
                    context,
                    item['title'] as String,
                    item['route'] as String,
                    isLast: index == _breadcrumbItems.length - 1,
                  );
                }).toList(),
              ),
            ),
          Expanded(
            // The main scrollable content area
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isLight
                      ? [
                          const Color(0xFFB3E5FC),
                          const Color(0xFF81D4FA),
                          const Color(0xFF0288D1),
                        ]
                      : [
                          const Color(0xFF18002F),
                          const Color(0xFF2C2448),
                          const Color(0xFF6966A7),
                        ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 34,
                    vertical: isMobile ? 10 : 24,
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page Heading and Description
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.money_off,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Smart Spending Limits',
                                  style: TextStyle(
                                    fontSize: isMobile ? 22 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set intelligent daily and monthly transaction limits based on your financial goals',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Progress & Steps
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Step $_currentStep of 2',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                '${((_currentStep / 2) * 100).toInt()}% Complete',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: _currentStep / 2,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                            minHeight: 8,
                          ),
                          const SizedBox(height: 20),

                          // Step Content
                          _currentStep == 1
                              ? _buildInputFormStep()
                              : _buildSpendingAnalytics(),

                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _currentStep > 1
                                    ? _previousStep
                                    : null,
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Previous'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isCurrentStepValid()
                                    ? _nextStep
                                    : null,
                                icon: Text(
                                  _currentStep == 1
                                      ? 'Calculate & View Analytics'
                                      : 'Start Over',
                                ),
                                label: Icon(
                                  _currentStep == 1
                                      ? Icons.insights
                                      : Icons.refresh,
                                  size: 18,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentStep == 1
                                      ? Colors.blue
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Input Form Step Widget ---
  Widget _buildInputFormStep() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      color: Theme.of(context).cardColor,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 24,
          vertical: isMobile ? 8 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Financial Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Help us calculate your optimal spending limits',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildFinancialInputFields(), // Reusing the input fields
            _dropdownField(
              label: "Risk Tolerance",
              value: _riskTolerance,
              items: [
                'Conservative - Prefer safety over flexibility',
                'Moderate - Balanced approach to spending',
                'Aggressive - Willing to spend more for goals',
              ],
              onChanged: (val) => setState(() => _riskTolerance = val),
              isRequired: true,
            ),
            _dropdownField(
              label: "Lifestyle",
              value: _lifestyle,
              items: [
                'Minimal - Basic needs focused',
                'Moderate - Balanced lifestyle',
                'Comfortable - Some luxuries',
                'Luxurious - Premium lifestyle',
              ],
              onChanged: (val) => setState(() => _lifestyle = val),
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build financial input fields
  List<Widget> _buildFinancialInputFields() {
    return [
      _formField(
        'Monthly Income (₹)',
        'e.g., 80000',
        _monthlyIncomeController,
        number: true,
        isRequired: true,
      ),
      _formField(
        'Fixed Monthly Expenses (₹)',
        'e.g., 45000',
        _fixedMonthlyExpensesController,
        number: true,
        isRequired: true,
      ),
      _formField(
        'Monthly Savings Goal (₹)',
        'e.g., 10000',
        _monthlySavingsGoalController,
        number: true,
        isRequired: true,
      ),
      _formField(
        'Current Emergency Fund (₹)',
        'e.g., 3243435',
        _currentEmergencyFundController,
        number: true,
      ),
      _formField(
        'Number of Dependents',
        'e.g., 2',
        _numDependentsController,
        number: true,
      ),
      _formField(
        'Current Monthly Debt Payments (₹)',
        'e.g., 22222',
        _currentMonthlyDebtPaymentsController,
        number: true,
        isRequired: true,
      ),
    ];
  }

  // --- Analytics Step Widget ---
  Widget _buildSpendingAnalytics() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Spending Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Here\'s how your monthly income is allocated and opportunities to save more:',
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 250, // Fixed size for the pie chart
                height: 250,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    data: _spendingAllocationData,
                    isLightMode: isLight,
                    showLegend: false, // Don't show legend inside painter
                  ),
                ),
              ),
            ),
            // --- Legend displayed outside CustomPaint ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _spendingAllocationData.entries.map((entry) {
                final List<Color> colors = [
                  Colors.blue.shade400,
                  Colors.green.shade400,
                  Colors.orange.shade400,
                  Colors.purple.shade400,
                  Colors.teal.shade400,
                  Colors.red.shade400,
                ];
                final int index = _spendingAllocationData.keys.toList().indexOf(
                  entry.key,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[index % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key}: ₹${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Recommended Spending Limits:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daily: ₹ ${_dailySpendingLimit.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly: ₹ ${_monthlySpendingLimit.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _spendingRecommendationMessage,
              style: TextStyle(
                fontSize: 15,
                color: subTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- Reusable TextField with label ---
  Widget _formField(
    String label,
    String hint,
    TextEditingController controller, {
    bool number = false,
    bool isRequired = false, // Added isRequired
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' (*)',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              keyboardType: number ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Dropdown with label ---
  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false, // Added isRequired
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' (*)',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: Text('Select your ${label.toLowerCase()}'),
              items: items
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: onChanged,
              validator: isRequired
                  ? (val) => val == null || val.isEmpty ? 'Required' : null
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW: Custom Painter for Pie Chart ---
class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final bool isLightMode;
  final bool showLegend; // New parameter to control legend drawing

  _PieChartPainter({
    required this.data,
    required this.isLightMode,
    this.showLegend = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double total = data.values.fold(0.0, (sum, item) => sum + item);
    if (total == 0) return;

    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    double startAngle = -pi / 2; // Start from top

    final List<Color> colors = [
      Colors.blue.shade400, // Fixed Expenses
      Colors.green.shade400, // Savings Goal
      Colors.orange.shade400, // Debt Payments
      Colors.purple.shade400, // Current Flexible Spending
      Colors.teal.shade400, // Recommended Investments/Insurance
      Colors.red.shade400, // Fallback
    ];

    int colorIndex = 0;
    for (var entry in data.entries) {
      final double sweepAngle = (entry.value / total) * 2 * pi;
      final Paint segmentPaint = Paint()
        ..color = colors[colorIndex % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true, // Use center to draw a pie slice
        segmentPaint,
      );

      // Draw text label on the segment
      final double midAngle = startAngle + sweepAngle / 2;
      final double textOffsetRadius =
          radius * 0.7; // Position text inside the slice
      final Offset textPosition = Offset(
        center.dx + textOffsetRadius * cos(midAngle),
        center.dy + textOffsetRadius * sin(midAngle),
      );

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '${(entry.value / total * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: isLightMode ? Colors.white : Colors.black, // Contrast color
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        textPosition - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      startAngle += sweepAngle;
      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.isLightMode != isLightMode ||
        oldDelegate.showLegend != showLegend;
  }
}
