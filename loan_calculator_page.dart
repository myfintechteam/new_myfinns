import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For logout functionality

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});
  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  String _selectedLoanType = 'Home Loan';

  // --- Breadcrumb Items for this page ---
  final List<Map<String, dynamic>> _breadcrumbItems = [
    {'title': 'Dashboard', 'route': '/home'},
    {'title': 'Loan Calculator', 'route': '/loan_calculator'},
  ];

  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  final TextEditingController _monthlyExpensesController =
      TextEditingController();
  String? _creditScore;
  String? _employmentType;
  String? _workExperience;
  final TextEditingController _existingMonthlyEMIsController =
      TextEditingController();

  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _propertyVehicleValueController =
      TextEditingController();
  final TextEditingController _courseFeeController = TextEditingController();
  final TextEditingController _scholarshipGrantsController =
      TextEditingController();
  final TextEditingController _businessTurnoverController =
      TextEditingController();
  final TextEditingController _businessVintageController =
      TextEditingController();

  final TextEditingController _desiredLoanAmountController =
      TextEditingController();
  String? _preferredTenure;

  String _eligibilityResult = '';

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _monthlyExpensesController.dispose();
    _existingMonthlyEMIsController.dispose();
    _downPaymentController.dispose();
    _propertyVehicleValueController.dispose();
    _courseFeeController.dispose();
    _scholarshipGrantsController.dispose();
    _businessTurnoverController.dispose();
    _businessVintageController.dispose();
    _desiredLoanAmountController.dispose();
    super.dispose();
  }

  void _calculateLoanEligibility() {
    double monthlyIncome =
        double.tryParse(_monthlyIncomeController.text) ?? 0.0;
    double monthlyExpenses =
        double.tryParse(_monthlyExpensesController.text) ?? 0.0;
    double existingEMIs =
        double.tryParse(_existingMonthlyEMIsController.text) ?? 0.0;
    double desiredLoanAmount =
        double.tryParse(_desiredLoanAmountController.text) ?? 0.0;
    int tenureYears =
        int.tryParse(_preferredTenure?.replaceAll(' years', '') ?? '0') ?? 0;

    double disposableIncome = monthlyIncome - monthlyExpenses - existingEMIs;
    double maxAffordableEMI = disposableIncome * 0.4;
    double theoreticalEMI = tenureYears > 0
        ? desiredLoanAmount / (tenureYears * 12)
        : 0.0;
    bool isEligible = true;
    String reason = '';

    if (monthlyIncome < 30000) {
      isEligible = false;
      reason += 'Minimum monthly income of ₹30,000 required. ';
    }
    if (disposableIncome <= 0) {
      isEligible = false;
      reason += 'Not enough disposable income. ';
    }
    if (theoreticalEMI > maxAffordableEMI && tenureYears > 0) {
      isEligible = false;
      reason += 'Desired loan amount is too high for your income and tenure. ';
    }
    if (_creditScore == 'Below 600') {
      isEligible = false;
      reason += 'Low credit score affects eligibility. ';
    } else if (_creditScore == '600-750' && desiredLoanAmount > 1000000) {
      isEligible = false;
      reason += 'Loan amount too high for moderate credit score. ';
    }

    if (_selectedLoanType == 'Home Loan') {
      double propertyValue =
          double.tryParse(_propertyVehicleValueController.text) ?? 0.0;
      double downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
      if (propertyValue == 0 || downPayment < propertyValue * 0.2) {
        isEligible = false;
        reason += 'Insufficient down payment for Home Loan. ';
      }
    } else if (_selectedLoanType == 'Car Loan') {
      double vehicleValue =
          double.tryParse(_propertyVehicleValueController.text) ?? 0.0;
      double downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
      if (vehicleValue == 0 || downPayment < vehicleValue * 0.1) {
        isEligible = false;
        reason += 'Insufficient down payment for Car Loan. ';
      }
    } else if (_selectedLoanType == 'Education Loan') {
      double courseFee = double.tryParse(_courseFeeController.text) ?? 0.0;
      if (courseFee == 0) {
        isEligible = false;
        reason += 'Course fee is required for Education Loan. ';
      }
    } else if (_selectedLoanType == 'Business Loan') {
      double turnover =
          double.tryParse(_businessTurnoverController.text) ?? 0.0;
      int vintage = int.tryParse(_businessVintageController.text) ?? 0;
      if (turnover < 500000 || vintage < 2) {
        isEligible = false;
        reason += 'Business does not meet turnover/vintage requirements. ';
      }
    }

    setState(() {
      if (isEligible) {
        _eligibilityResult = 'Eligible! You are likely eligible for this loan.';
      } else {
        _eligibilityResult =
            'Not Eligible. Reason(s): ${reason.isEmpty ? 'Criteria not met.' : reason}';
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

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              items: options
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
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

  Widget _buildLoanTypeButton(String type, IconData icon, bool isSelected) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLoanType = type;
          _eligibilityResult = '';
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.blue,
              size: isMobile ? 26 : 30,
            ),
            SizedBox(height: 6),
            Text(
              type.replaceAll(' Loan', ''),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleFieldRow(List<Widget> children, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [children[0], const SizedBox(height: 12), children[1]],
      );
    }
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 24),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildHomeLoanFields(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide details specific to your home loan application',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildDoubleFieldRow([
          _buildTextField(
            'Down Payment (₹)',
            'e.g., 500000',
            _downPaymentController,
            isNumber: true,
          ),
          _buildTextField(
            'Property Value (₹)',
            'e.g., 2500000',
            _propertyVehicleValueController,
            isNumber: true,
          ),
        ], isMobile),
      ],
    );
  }

  Widget _buildCarLoanFields(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide details specific to your car loan application',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildDoubleFieldRow([
          _buildTextField(
            'Down Payment (₹)',
            'e.g., 500000',
            _downPaymentController,
            isNumber: true,
          ),
          _buildTextField(
            'Vehicle Value (₹)',
            'e.g., 2500000',
            _propertyVehicleValueController,
            isNumber: true,
          ),
        ], isMobile),
      ],
    );
  }

  Widget _buildEducationLoanFields(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide details specific to your education loan application',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildDoubleFieldRow([
          _buildTextField(
            'Course Fee (₹)',
            'e.g., 1000000',
            _courseFeeController,
            isNumber: true,
          ),
          _buildTextField(
            'Scholarship/Grants (₹)',
            'e.g., 100000',
            _scholarshipGrantsController,
            isNumber: true,
          ),
        ], isMobile),
      ],
    );
  }

  Widget _buildBusinessLoanFields(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide details specific to your business loan application',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildDoubleFieldRow([
          _buildTextField(
            'Business Turnover (₹)',
            'e.g., 5000000',
            _businessTurnoverController,
            isNumber: true,
          ),
          _buildTextField(
            'Business Vintage (years)',
            'e.g., 3',
            _businessVintageController,
            isNumber: true,
          ),
        ], isMobile),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isDesktop = width >= 900; // allow full width on large screens
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
              // Placeholder action for theme toggle
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
                    horizontal:
                        (width >
                            900 // isWideWeb
                        ? 0
                        : isMobile
                        ? 8
                        : 32),
                    vertical: isMobile ? 8 : 24,
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: width > 900 ? double.infinity : 600,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page title and subtitle
                          Row(
                            children: [
                              Icon(
                                Icons.payments,
                                size: 32,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loan Calculator',
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Calculate your loan eligibility and get personalized recommendations',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Loan type selection
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                // Mobile layout
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _buildLoanTypeButton(
                                            'Home Loan',
                                            Icons.home,
                                            _selectedLoanType == 'Home Loan',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildLoanTypeButton(
                                            'Car Loan',
                                            Icons.directions_car,
                                            _selectedLoanType == 'Car Loan',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildLoanTypeButton(
                                            'Education Loan',
                                            Icons.school,
                                            _selectedLoanType ==
                                                'Education Loan',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _buildLoanTypeButton(
                                            'Business Loan',
                                            Icons.business,
                                            _selectedLoanType ==
                                                'Business Loan',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildLoanTypeButton(
                                            'Personal Loan',
                                            Icons.person,
                                            _selectedLoanType ==
                                                'Personal Loan',
                                          ),
                                        ),
                                        const Expanded(
                                          child: SizedBox(),
                                        ), // Empty space to balance
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                // Desktop layout
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildLoanTypeButton(
                                        'Home Loan',
                                        Icons.home,
                                        _selectedLoanType == 'Home Loan',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildLoanTypeButton(
                                        'Car Loan',
                                        Icons.directions_car,
                                        _selectedLoanType == 'Car Loan',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildLoanTypeButton(
                                        'Education Loan',
                                        Icons.school,
                                        _selectedLoanType == 'Education Loan',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildLoanTypeButton(
                                        'Business Loan',
                                        Icons.business,
                                        _selectedLoanType == 'Business Loan',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildLoanTypeButton(
                                        'Personal Loan',
                                        Icons.person,
                                        _selectedLoanType == 'Personal Loan',
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          // Card with form content - width: 100% on web
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    (width >
                                        900 // isWideWeb
                                    ? 32
                                    : isMobile
                                    ? 12
                                    : 28),
                                vertical: isMobile ? 12 : 28,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Financial Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Provide your financial details for accurate assessment',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  isMobile
                                      ? Column(
                                          children: [
                                            _buildTextField(
                                              'Monthly Income (₹)',
                                              'e.g., 80000',
                                              _monthlyIncomeController,
                                              isNumber: true,
                                            ),
                                            _buildTextField(
                                              'Monthly Expenses (₹)',
                                              'e.g., 45000',
                                              _monthlyExpensesController,
                                              isNumber: true,
                                            ),
                                            _buildDropdownField(
                                              label: "Credit Score",
                                              value: _creditScore,
                                              options: [
                                                'Excellent (750+)',
                                                'Good (680-749)',
                                                'Fair (600-679)',
                                                'Below 600',
                                              ],
                                              onChanged: (val) => setState(
                                                () => _creditScore = val,
                                              ),
                                            ),
                                            _buildDropdownField(
                                              label: "Employment Type",
                                              value: _employmentType,
                                              options: [
                                                'Salaried',
                                                'Self-Employed',
                                                'Business Owner',
                                                'Student',
                                              ],
                                              onChanged: (val) => setState(
                                                () => _employmentType = val,
                                              ),
                                            ),
                                            _buildDropdownField(
                                              label: "Work Experience",
                                              value: _workExperience,
                                              options: [
                                                '< 1 year',
                                                '1-3 years',
                                                '3-5 years',
                                                '5+ years',
                                              ],
                                              onChanged: (val) => setState(
                                                () => _workExperience = val,
                                              ),
                                            ),
                                            _buildTextField(
                                              'Existing Monthly EMIs (₹)',
                                              'e.g., 12000',
                                              _existingMonthlyEMIsController,
                                              isNumber: true,
                                            ),
                                          ],
                                        )
                                      : GridView.count(
                                          crossAxisCount: 2,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisSpacing: 24,
                                          mainAxisSpacing: 24,
                                          childAspectRatio: 3.7,
                                          children: [
                                            _buildTextField(
                                              'Monthly Income (₹)',
                                              'e.g., 80000',
                                              _monthlyIncomeController,
                                              isNumber: true,
                                            ),
                                            _buildTextField(
                                              'Monthly Expenses (₹)',
                                              'e.g., 45000',
                                              _monthlyExpensesController,
                                              isNumber: true,
                                            ),
                                            _buildDropdownField(
                                              label: "Credit Score",
                                              value: _creditScore,
                                              options: [
                                                'Excellent (750+)',
                                                'Good (680-749)',
                                                'Fair (600-679)',
                                                'Below 600',
                                              ],
                                              onChanged: (val) => setState(
                                                () => _creditScore = val,
                                              ),
                                            ),
                                            _buildDropdownField(
                                              label: "Employment Type",
                                              value: _employmentType,
                                              options: [
                                                'Salaried',
                                                'Self-Employed',
                                                'Business Owner',
                                                'Student',
                                              ],
                                              onChanged: (val) => setState(
                                                () => _employmentType = val,
                                              ),
                                            ),
                                            _buildDropdownField(
                                              label: "Work Experience",
                                              value: _workExperience,
                                              options: [
                                                '< 1 year',
                                                '1-3 years',
                                                '3-5 years',
                                                '5+ years',
                                              ],
                                              onChanged: (val) => setState(
                                                () => _workExperience = val,
                                              ),
                                            ),
                                            _buildTextField(
                                              'Existing Monthly EMIs (₹)',
                                              'e.g., 12000',
                                              _existingMonthlyEMIsController,
                                              isNumber: true,
                                            ),
                                          ],
                                        ),
                                  if (_selectedLoanType == 'Home Loan')
                                    _buildHomeLoanFields(isMobile),
                                  if (_selectedLoanType == 'Car Loan')
                                    _buildCarLoanFields(isMobile),
                                  if (_selectedLoanType == 'Education Loan')
                                    _buildEducationLoanFields(isMobile),
                                  if (_selectedLoanType == 'Business Loan')
                                    _buildBusinessLoanFields(isMobile),
                                  const SizedBox(height: 24),
                                  _buildDoubleFieldRow([
                                    _buildTextField(
                                      'Desired Loan Amount (₹)',
                                      'e.g., 2000000',
                                      _desiredLoanAmountController,
                                      isNumber: true,
                                    ),
                                    _buildDropdownField(
                                      label: 'Preferred Tenure (years)',
                                      value: _preferredTenure,
                                      options: [
                                        '5 years',
                                        '10 years',
                                        '15 years',
                                        '20 years',
                                        '25 years',
                                        '30 years',
                                      ],
                                      onChanged: (val) => setState(
                                        () => _preferredTenure = val,
                                      ),
                                    ),
                                  ], isMobile),
                                  const SizedBox(height: 32),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _calculateLoanEligibility,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 30,
                                          vertical: 15,
                                        ),
                                      ),
                                      child: const Text(
                                        'Calculate Loan Eligibility',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_eligibilityResult.isNotEmpty)
                                    Center(
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Loan Eligibility Result:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _eligibilityResult,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  _eligibilityResult.startsWith(
                                                    'Eligible',
                                                  )
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
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
}
