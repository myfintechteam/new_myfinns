import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user's UID
import 'package:http/http.dart' as http; // For making HTTP requests to backend
import 'dart:convert'; // For JSON encoding/decoding
import 'dart:math'; // For mathematical operations in CustomPainter
import 'package:myfin/constants.dart'; // NEW: Import your constants file

class InsuranceCalculatorPage extends StatefulWidget {
  const InsuranceCalculatorPage({super.key});

  @override
  State<InsuranceCalculatorPage> createState() =>
      _InsuranceCalculatorPageState();
}

class _InsuranceCalculatorPageState extends State<InsuranceCalculatorPage> {
  int _currentStep = 1;
  bool _isLoadingProfile = true; // New state to manage profile loading
  bool _isSavingCalculation = false; // New state for saving calculation

  // // Define your backend API URL
  // final String _backendBaseUrl =
  //     'http://localhost:3000'; // IMPORTANT: Replace with your actual Node.js backend port
  // Use the new constant for the backend URL
  final String _backendBaseUrl = AppConstants.backendBaseUrl;

  // --- Breadcrumb Items for this page ---
  final List<Map<String, dynamic>> _breadcrumbItems = [
    {'title': 'Dashboard', 'route': '/home'},
    {'title': 'Insurance Calculator', 'route': '/insurance_calculator'},
  ];

  // --- Basic Customer & Policy Info Fields ---
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _annualIncomeController = TextEditingController();
  String? _maritalStatus;
  final TextEditingController _numChildrenController = TextEditingController();
  final TextEditingController _spouseIncomeController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Health & Lifestyle
  String? _smokingHabit;
  String? _drinkingHabit;
  String? _selectedMedicalCondition; // Changed to single select
  String? _selectedFamilyMedicalCondition; // Changed to single select
  final TextEditingController _currentMedicationsController =
      TextEditingController();
  String? _exerciseFrequency;

  // Policy & Financial Data
  final TextEditingController _existingLifeInsuranceController =
      TextEditingController();
  String? _policyType;
  String? _selectedInvestmentGoal; // Changed to single select
  final TextEditingController _debtsController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();

  // --- Calculated & Analytics Results ---
  double _calculatedInsuranceAmount = 0.0;
  double _bmi = 0.0; // Calculated BMI
  String? _profileFetchError; // To display error if profile fetch fails

  // --- Analytics Messages ---
  String _riskProfileMessage = '';
  String _coverageGapMessage = '';
  String _premiumAffordabilityMessage = '';
  String _mortalityRiskMessage = '';
  String _policyPerformanceMessage = '';
  String _eligibilityOdometerMessage = '';
  double _eligibilityPercentage = 0.0; // For odometer-like visual

  // Data for charts (example data, replace with actual dynamic data if needed)
  List<double> _coverageTrendData = [
    1000000,
    1200000,
    1500000,
    1300000,
    1800000,
    2000000,
  ];
  Map<String, double> _riskFactorData = {
    'Health': 0.3,
    'Lifestyle': 0.2,
    'Age': 0.1,
    'Other': 0.4,
  };
  Map<String, double> _premiumAllocationData = {
    'Premium': 0.1,
    'Savings': 0.4,
    'Expenses': 0.5,
  };
  List<double> _policyGrowthData = [
    0.0,
    0.05,
    0.1,
    0.08,
    0.12,
    0.15,
  ]; // Example growth over time

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user profile when the page initializes
  }

  @override
  void dispose() {
    _ageController.dispose();
    _annualIncomeController.dispose();
    _numChildrenController.dispose();
    _spouseIncomeController.dispose();
    _occupationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    _currentMedicationsController.dispose();
    _existingLifeInsuranceController.dispose();
    _debtsController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  // New method to fetch user profile from the backend
  Future<void> _fetchUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingProfile = false;
        _profileFetchError = 'No authenticated user found.';
      });
      return;
    }

    //   try {
    //     final response = await http.get(
    //       Uri.parse('$_backendBaseUrl/api/profile/${user.uid}'),
    //     );

    //     if (response.statusCode == 200) {
    //       final Map<String, dynamic> data = json.decode(response.body);
    //       setState(() {
    //         // Populate controllers and state variables with fetched data
    //         _ageController.text = (data['age'] ?? '').toString();
    //         _selectedGender = data['gender'];
    //         _annualIncomeController.text = (data['monthly_income'] != null
    //             ? (data['monthly_income'] * 12).toStringAsFixed(2)
    //             : '');
    //         _maritalStatus = data['marital_status'];
    //         _numChildrenController.text = (data['dependents'] ?? '').toString();
    //         _occupationController.text = data['occupation'] ?? '';
    //         _heightController.text = (data['height_cm'] ?? '').toString();
    //         _weightController.text = (data['weight_kg'] ?? '').toString();
    //         _locationController.text = data['location'] ?? '';
    //         _smokingHabit = data['smoking_habit'];
    //         _drinkingHabit = data['drinking_habit'];
    //         // For single select, pick the first if available, else null
    //         _selectedMedicalCondition =
    //             (data['medical_history'] as List?)?.isNotEmpty == true
    //             ? data['medical_history'][0]
    //             : null;
    //         _selectedFamilyMedicalCondition =
    //             (data['family_medical_history'] as List?)?.isNotEmpty == true
    //             ? data['family_medical_history'][0]
    //             : null;
    //         _currentMedicationsController.text =
    //             data['current_medications'] ?? '';
    //         _exerciseFrequency = data['exercise_frequency'];

    //         _existingLifeInsuranceController.text =
    //             (data['existing_insurance'] != null &&
    //                         data['existing_insurance'] != 'None'
    //                     ? _extractAmountFromInsuranceString(
    //                         data['existing_insurance'],
    //                       )
    //                     : 0.0)
    //                 .toStringAsFixed(2);
    //         _policyType = data['policy_type'];
    //         _selectedInvestmentGoal =
    //             (data['investment_goals'] as List?)?.isNotEmpty == true
    //             ? data['investment_goals'][0]
    //             : null;
    //         _debtsController.text =
    //             (data['existing_loans'] != null &&
    //                         data['existing_loans'] != 'None'
    //                     ? _extractAmountFromLoansString(data['existing_loans'])
    //                     : 0.0)
    //                 .toStringAsFixed(2);
    //         _savingsController.text =
    //             (data['existing_savings_investments'] is num
    //                     ? (data['existing_savings_investments'] as num).toDouble()
    //                     : 0.0)
    //                 .toStringAsFixed(2);

    //         _isLoadingProfile = false;
    //         // Calculate BMI if height and weight are available
    //         _calculateBMI();
    //       });
    //     } else if (response.statusCode == 404) {
    //       setState(() {
    //         _isLoadingProfile = false;
    //         _profileFetchError =
    //             'Profile not found. Please complete your profile setup.';
    //       });
    //     } else {
    //       setState(() {
    //         _isLoadingProfile = false;
    //         _profileFetchError = 'Failed to load profile: ${response.statusCode}';
    //       });
    //       print('Backend error: ${response.statusCode} - ${response.body}');
    //     }
    //   } catch (e) {
    //     setState(() {
    //       _isLoadingProfile = false;
    //       _profileFetchError =
    //           'Network error: ${e.toString()}. Is backend running?';
    //     });
    //     print('Network error fetching profile: $e');
    //   }
    // }
    // ADD THIS:
    setState(() {
      _isLoadingProfile = false;
      _profileFetchError = null;
      // Leave all field values as manually blank.
    });
  }

  // Helper to extract numeric amount from existing_insurance string
  double _extractAmountFromInsuranceString(String? insuranceString) {
    if (insuranceString == null ||
        insuranceString.toLowerCase() == 'none' ||
        insuranceString.isEmpty) {
      return 0.0;
    }
    final RegExp regex = RegExp(
      r'(\d+(\.\d+)?)\s*(lakhs|lakh|million|crore)?',
      caseSensitive: false,
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(insuranceString);
    double totalAmount = 0.0;
    for (final m in matches) {
      final double value = double.tryParse(m.group(1)!) ?? 0.0;
      final String unit = (m.group(3) ?? '').toLowerCase();
      if (unit.contains('lakh')) {
        totalAmount += value * 100000;
      } else if (unit.contains('million')) {
        totalAmount += value * 1000000;
      } else if (unit.contains('crore')) {
        totalAmount += value * 10000000;
      } else {
        totalAmount += value;
      }
    }
    return totalAmount;
  }

  // Helper to extract numeric amount from existing_loans string
  double _extractAmountFromLoansString(String? loansString) {
    if (loansString == null ||
        loansString.toLowerCase() == 'none' ||
        loansString.isEmpty) {
      return 0.0;
    }
    final RegExp regex = RegExp(
      r'(\d+(\.\d+)?)\s*(lakhs|lakh|million|crore)?',
      caseSensitive: false,
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(loansString);
    double totalAmount = 0.0;
    for (final m in matches) {
      final double value = double.tryParse(m.group(1)!) ?? 0.0;
      final String unit = (m.group(3) ?? '').toLowerCase();
      if (unit.contains('lakh')) {
        totalAmount += value * 100000;
      } else if (unit.contains('million')) {
        totalAmount += value * 1000000;
      } else if (unit.contains('crore')) {
        totalAmount += value * 10000000;
      } else {
        totalAmount += value;
      }
    }
    return totalAmount;
  }

  // Helper to calculate BMI
  void _calculateBMI() {
    final double? heightCm = double.tryParse(_heightController.text);
    final double? weightKg = double.tryParse(_weightController.text);

    if (heightCm != null && weightKg != null && heightCm > 0) {
      setState(() {
        _bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
      });
    } else {
      setState(() {
        _bmi = 0.0;
      });
    }
  }

  // NEW: Validation for current step
  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 1: // Personal Information
        return _ageController.text.isNotEmpty &&
            _annualIncomeController.text.isNotEmpty &&
            _selectedGender != null &&
            _selectedGender!
                .isNotEmpty && // Ensure gender is selected and not empty
            _occupationController.text.isNotEmpty &&
            _heightController.text.isNotEmpty &&
            _weightController.text.isNotEmpty &&
            _locationController.text.isNotEmpty;
      case 2: // Family Details
        return _maritalStatus != null &&
            _maritalStatus!
                .isNotEmpty && // Ensure marital status is selected and not empty
            _numChildrenController.text.isNotEmpty;
      case 3: // Health & Lifestyle
        return _smokingHabit != null &&
            _smokingHabit!.isNotEmpty &&
            _drinkingHabit != null &&
            _drinkingHabit!.isNotEmpty &&
            _selectedMedicalCondition != null &&
            _selectedMedicalCondition!.isNotEmpty && // Single select validation
            _selectedFamilyMedicalCondition != null &&
            _selectedFamilyMedicalCondition!
                .isNotEmpty && // Single select validation
            _exerciseFrequency != null &&
            _exerciseFrequency!.isNotEmpty;
      case 4: // Finances & Calculation
        return _debtsController.text.isNotEmpty &&
            _savingsController.text.isNotEmpty &&
            _policyType != null &&
            _policyType!.isNotEmpty &&
            _selectedInvestmentGoal != null &&
            _selectedInvestmentGoal!.isNotEmpty; // Single select validation
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_isCurrentStepValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields in the current step.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      if (_currentStep < 5) {
        // Adjusted for 5 steps (including analytics)
        _currentStep++;
        if (_currentStep == 5) {
          _calculateInsurance(); // Calculate on reaching the analytics step
        }
      } else {
        // If on last step (analytics) and click next, it resets
        _currentStep = 1;
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
    _ageController.clear();
    _selectedGender = null;
    _annualIncomeController.clear();
    _maritalStatus = null;
    _numChildrenController.clear();
    _spouseIncomeController.clear();
    _occupationController.clear();
    _heightController.clear();
    _weightController.clear();
    _locationController.clear();
    _smokingHabit = null;
    _drinkingHabit = null;
    _selectedMedicalCondition = null; // Reset to null for single select
    _selectedFamilyMedicalCondition = null; // Reset to null for single select
    _currentMedicationsController.clear();
    _exerciseFrequency = null;
    _existingLifeInsuranceController.clear();
    _policyType = null;
    _selectedInvestmentGoal = null; // Reset to null for single select
    _debtsController.clear();
    _savingsController.clear();
    _calculatedInsuranceAmount = 0.0;
    _bmi = 0.0;
    _profileFetchError = null;
    _isLoadingProfile = true;
    _isSavingCalculation = false;

    // Reset analytics messages
    _riskProfileMessage = '';
    _coverageGapMessage = '';
    _premiumAffordabilityMessage = '';
    _mortalityRiskMessage = '';
    _policyPerformanceMessage = '';
    _eligibilityOdometerMessage = '';
    _eligibilityPercentage = 0.0;

    // Reset chart data (example)
    _coverageTrendData = [1000000, 1200000, 1500000, 1300000, 1800000, 2000000];
    _riskFactorData = {
      'Health': 0.3,
      'Lifestyle': 0.2,
      'Age': 0.1,
      'Other': 0.4,
    };
    _premiumAllocationData = {'Premium': 0.1, 'Savings': 0.4, 'Expenses': 0.5};
    _policyGrowthData = [0.0, 0.05, 0.1, 0.08, 0.12, 0.15];

    _fetchUserProfile(); // Re-fetch profile on reset
  }

  // NEW: Method to save insurance calculation to backend
  Future<void> _saveInsuranceCalculation() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No authenticated user to save calculation.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSavingCalculation = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/insurance-calculation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firebase_uid': user.uid,
          'age': int.tryParse(_ageController.text),
          'gender': _selectedGender,
          'annual_income': double.tryParse(_annualIncomeController.text),
          'marital_status': _maritalStatus,
          'num_children': int.tryParse(_numChildrenController.text),
          'spouse_annual_income': double.tryParse(_spouseIncomeController.text),
          'occupation': _occupationController.text,
          'height_cm': double.tryParse(_heightController.text),
          'weight_kg': double.tryParse(_weightController.text),
          'location': _locationController.text,
          'smoking_habit': _smokingHabit,
          'drinking_habit': _drinkingHabit,
          'medical_history': _selectedMedicalCondition, // Single select
          'family_medical_history':
              _selectedFamilyMedicalCondition, // Single select
          'current_medications': _currentMedicationsController.text,
          'exercise_frequency': _exerciseFrequency,
          'existing_life_insurance': double.tryParse(
            _existingLifeInsuranceController.text,
          ),
          'policy_type': _policyType,
          'investment_goals': _selectedInvestmentGoal, // Single select
          'total_debts': double.tryParse(_debtsController.text),
          'total_savings_investments': double.tryParse(_savingsController.text),
          'calculated_insurance_amount': _calculatedInsuranceAmount,
          // Analytics results (optional, could be stored or re-derived)
          'risk_profile_message': _riskProfileMessage,
          'coverage_gap_message': _coverageGapMessage,
          'premium_affordability_message': _premiumAffordabilityMessage,
          'mortality_risk_message': _mortalityRiskMessage,
          'policy_performance_message': _policyPerformanceMessage,
          'eligibility_odometer_message': _eligibilityOdometerMessage,
          'eligibility_percentage': _eligibilityPercentage,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insurance calculation saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save calculation: ${errorData['error'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        print('Backend save error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error saving calculation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Network error saving calculation: $e');
    } finally {
      setState(() {
        _isSavingCalculation = false;
      });
    }
  }

  void _calculateInsurance() {
    // Ensure BMI is calculated before proceeding
    _calculateBMI();

    // Basic validation to ensure required fields are filled (already done in _isCurrentStepValid)
    // Here we assume all required fields are available

    double age = double.tryParse(_ageController.text) ?? 0;
    double annualIncome = double.tryParse(_annualIncomeController.text) ?? 0;
    int numChildren = int.tryParse(_numChildrenController.text) ?? 0;
    double debts = double.tryParse(_debtsController.text) ?? 0;
    double savings = double.tryParse(_savingsController.text) ?? 0;
    double existingLifeInsurance =
        double.tryParse(_existingLifeInsuranceController.text) ?? 0;
    double spouseAnnualIncome =
        double.tryParse(_spouseIncomeController.text) ?? 0;

    // DIME Methodology-inspired Calculation
    // D - Debts: Cover all outstanding debts
    // I - Income: 10-15x annual income (adjusted for age, health)
    // M - Mortgage: If applicable, consider covering mortgage (part of debts)
    // E - Education: Future education costs for children

    double incomeMultiplier = 12; // Start with 12x income
    double educationCostPerChild = 1000000; // Example: 10 Lakh per child
    double emergencyFundYears = 0.5; // 6 months of income for emergencies

    double baseInsuranceNeeded =
        (annualIncome * incomeMultiplier) +
        (numChildren * educationCostPerChild) +
        debts +
        (annualIncome * emergencyFundYears) -
        savings -
        existingLifeInsurance;

    // --- Risk Adjustments ---
    double riskFactor = 1.0;

    // Age
    if (age <= 30)
      riskFactor *= 1.1; // Younger might need more coverage longer
    else if (age >= 50)
      riskFactor *= 0.9; // Less years of income to replace

    // Smoking
    if (_smokingHabit == 'Yes') riskFactor *= 1.2;

    // Drinking
    if (_drinkingHabit == 'Daily' || _drinkingHabit == 'Frequently')
      riskFactor *= 1.15;

    // BMI (Underweight < 18.5, Overweight > 25, Obese > 30)
    if (_bmi > 25 || _bmi < 18.5)
      riskFactor *= 1.05; // Slight increase for non-ideal BMI
    if (_bmi > 30) riskFactor *= 1.1; // Higher increase for obese

    // Health Conditions
    if (_selectedMedicalCondition == 'Major')
      riskFactor *= 1.2;
    else if (_selectedMedicalCondition == 'Minor')
      riskFactor *= 1.1;
    if (_selectedFamilyMedicalCondition == 'Major') riskFactor *= 1.1;

    // Exercise Frequency
    if (_exerciseFrequency == 'Never' || _exerciseFrequency == 'Rarely')
      riskFactor *= 1.05;

    // Apply risk factor
    baseInsuranceNeeded *= riskFactor;

    // Ensure it's not negative
    _calculatedInsuranceAmount = baseInsuranceNeeded > 0
        ? baseInsuranceNeeded
        : 1000000; // Minimum 10 Lakh

    // Round to nearest Lakh for readability
    _calculatedInsuranceAmount =
        (_calculatedInsuranceAmount / 100000).roundToDouble() * 100000;

    // --- Generate Analytics Messages ---
    String riskCategory;
    if (riskFactor > 1.2)
      riskCategory = 'High';
    else if (riskFactor > 1.05)
      riskCategory = 'Medium';
    else
      riskCategory = 'Low';

    _riskProfileMessage = 'Your current risk profile is: $riskCategory.';

    double coverageGap = _calculatedInsuranceAmount - existingLifeInsurance;
    if (coverageGap > 0) {
      _coverageGapMessage =
          'You are under-insured by ₹${coverageGap.toStringAsFixed(0)}. Consider increasing your coverage.';
    } else {
      _coverageGapMessage =
          'Your current coverage is adequate or even over-insured. Good job!';
    }

    double affordablePremiumPercentage =
        0.1; // 10% of annual income as affordable premium
    double maxAffordablePremium = annualIncome * affordablePremiumPercentage;
    _premiumAffordabilityMessage =
        'Based on your income, an annual premium up to ₹${maxAffordablePremium.toStringAsFixed(0)} is generally affordable. Look for plans within this range.';

    String mortalityScore;
    if (age > 60 ||
        _smokingHabit == 'Yes' ||
        _drinkingHabit == 'Daily' ||
        _bmi > 30 ||
        _selectedMedicalCondition == 'Major') {
      mortalityScore = 'High';
    } else if (age > 45 || _bmi > 25 || _selectedMedicalCondition == 'Minor') {
      mortalityScore = 'Medium';
    } else {
      mortalityScore = 'Low';
    }
    _mortalityRiskMessage =
        'Your estimated mortality risk score is: $mortalityScore. This can influence your premium.';

    if (_policyType == 'ULIP' && _selectedInvestmentGoal == 'High Growth') {
      _policyPerformanceMessage =
          'For your ULIP and High Growth goals, regularly review fund performance against market benchmarks like Nifty 50. Consider rebalancing if underperforming for 2-3 consecutive years.';
    } else if (_policyType == 'Term Insurance' &&
        annualIncome > 1000000 &&
        coverageGap > 0) {
      _policyPerformanceMessage =
          'As a high-income earner with a potential coverage gap, a pure Term plan is often the most cost-effective way to get maximum coverage. Look for online term plans for competitive premiums.';
    } else {
      _policyPerformanceMessage =
          'Consider matching your policy type with your life goals. A Term plan for protection, Whole Life for long-term savings, or ULIP for market-linked returns.';
    }

    // Eligibility Odometer (Example: How close are they to an ideal coverage amount based on simplified criteria)
    double idealCoverageMax =
        (annualIncome * 15) +
        (debts * 1.2) +
        (numChildren * educationCostPerChild * 1.5);
    _eligibilityPercentage = (_calculatedInsuranceAmount / idealCoverageMax)
        .clamp(0.0, 1.0); // Clamp between 0 and 1
    _eligibilityOdometerMessage =
        'Eligible up to ₹${(idealCoverageMax * 1.2).toStringAsFixed(0)} based on your profile.'; // Show a slightly higher potential
    if (annualIncome == 0 || age == 0) {
      // Avoid division by zero
      _eligibilityPercentage = 0;
      _eligibilityOdometerMessage =
          'Please provide income and age to calculate eligibility.';
    }

    // Update chart data based on calculation (example)
    _coverageTrendData = [
      existingLifeInsurance,
      _calculatedInsuranceAmount * 0.8,
      _calculatedInsuranceAmount,
      _calculatedInsuranceAmount * 1.1,
      _calculatedInsuranceAmount * 1.2,
    ];
    _riskFactorData = {
      'Health': (_selectedMedicalCondition == 'Major'
          ? 0.4
          : (_selectedMedicalCondition == 'Minor' ? 0.2 : 0.1)),
      'Lifestyle':
          (_smokingHabit == 'Yes' ? 0.3 : 0.1) +
          (_drinkingHabit == 'Daily' ? 0.2 : 0.05),
      'Age': (age > 50 ? 0.2 : (age < 30 ? 0.1 : 0.05)),
      'Financial': (debts / (annualIncome + spouseAnnualIncome + 1)).clamp(
        0.0,
        0.3,
      ), // Clamp to prevent too large values
    };
    double totalRisk = _riskFactorData.values.fold(
      0.0,
      (sum, item) => sum + item,
    );
    _riskFactorData.updateAll(
      (key, value) => value / totalRisk,
    ); // Normalize to sum to 1

    _premiumAllocationData = {
      'Premium': (maxAffordablePremium / (annualIncome + 1)).clamp(
        0.0,
        0.2,
      ), // Max 20% of income
      'Savings': (savings / (annualIncome + 1)).clamp(0.0, 0.3),
      'Expenses':
          1.0 -
          (maxAffordablePremium / (annualIncome + 1)).clamp(0.0, 0.2) -
          (savings / (annualIncome + 1)).clamp(0.0, 0.3),
    };
    _premiumAllocationData.updateAll(
      (key, value) => value.clamp(0.0, 1.0),
    ); // Ensure values are between 0 and 1

    // Example policy growth data (can be more sophisticated)
    _policyGrowthData = List.generate(
      6,
      (index) => _calculatedInsuranceAmount * (1 + index * 0.02),
    ); // 2% growth per period

    // Save the calculation after it's performed (now includes analytics results)
    _saveInsuranceCalculation();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth >= 900; // Assuming desktop for breadcrumbs
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
              // Changed from Image.network to Image.asset
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
          // // Theme Toggle
          // IconButton(
          //   icon: Icon(
          //     Theme.of(context).brightness == Brightness.light
          //         ? Icons.dark_mode
          //         : Icons.light_mode,
          //   ),
          //   onPressed: () {
          //     // This page doesn't have direct access to toggleTheme, it's passed from MyApp
          //     // For a standalone page, you might need to use a Provider or inherited widget
          //     // For now, assuming toggleTheme is available if this page is part of a larger app
          //     // as per previous context, but it's not directly in this page's widget tree.
          //     // If you need it here, you'd need to pass it down from MyApp.
          //     // For demonstration, I'll use a placeholder action.
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text(
          //           'Theme toggle not directly available on this page.',
          //         ),
          //       ),
          //     );
          //   },
          // ),
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
        bottom: isDesktop
            ? PreferredSize(
                preferredSize: const Size.fromHeight(
                  40.0,
                ), // Match main.dart breadcrumb height
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.04),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                        width: 2,
                      ),
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
              )
            : null,
        shape: Border(
          // Match main.dart AppBar bottom border
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 32,
            vertical: isMobile ? 8 : 24,
          ),
          child: _isLoadingProfile
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : _profileFetchError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _profileFetchError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchUserProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Load Profile'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Heading and Badge (kept for consistency with other pages' main content)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Get personalized insurance recommendations for you and your family using professional DIME methodology',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'AI-Powered Analysis',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Step $_currentStep of 5', // Adjusted for 5 steps
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            '${((_currentStep / 5) * 100).toInt()}% Complete', // Adjusted for 5 steps
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
                        value: _currentStep / 5, // Adjusted for 5 steps
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 20),
                      // Stepper Row (horizontal scroll for mobile)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStepIndicator(
                              1,
                              'Personal Info',
                              Icons.person,
                              _currentStep == 1,
                            ),
                            _buildStepIndicator(
                              2,
                              'Family Details',
                              Icons.family_restroom,
                              _currentStep == 2,
                            ),
                            _buildStepIndicator(
                              3,
                              'Health & Lifestyle',
                              Icons.favorite_border,
                              _currentStep == 3,
                            ),
                            _buildStepIndicator(
                              4,
                              'Finances',
                              Icons.attach_money,
                              _currentStep == 4,
                            ),
                            _buildStepIndicator(
                              5,
                              'Analytics',
                              Icons.analytics,
                              _currentStep == 5,
                            ), // NEW Step for Analytics
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // STEP CONTENT (forms for the current step)
                      _buildStepContent(_currentStep),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _currentStep > 1 ? _previousStep : null,
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
                          // Modified Next Step button with validation
                          _currentStep == 5
                              ? ElevatedButton.icon(
                                  onPressed:
                                      _resetForm, // Reset button on final step
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Start Over'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors
                                        .grey, // Different color for reset
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _isCurrentStepValid()
                                      ? _nextStep
                                      : null,
                                  icon: Text(
                                    _currentStep == 4
                                        ? 'Calculate & View Analytics'
                                        : 'Next Step', // Changed text for Step 4
                                  ),
                                  label: Icon(
                                    _currentStep == 4
                                        ? Icons.insights
                                        : Icons
                                              .arrow_forward, // Different icon for Step 4
                                    size: 18,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
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
    );
  }

  Widget _buildStepIndicator(
    int step,
    String title,
    IconData icon,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey[200],
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step $step',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 1:
        return _buildPersonalInformationStep();
      case 2:
        return _buildFamilyDetailsStep();
      case 3:
        return _buildHealthLifestyleStep();
      case 4:
        return _buildFinancesCalculationStep();
      case 5: // NEW: Analytics Step
        return _buildAnalyticsSuggestions();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalInformationStep() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800), // Reduce as needed
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Help us understand your basic profile',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 450) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldWithLabel(
                            'Age',
                            _ageController,
                            hint: 'e.g., 30',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                          const SizedBox(height: 18),
                          _dropdownWithLabel(
                            'Gender',
                            _selectedGender,
                            ['Male', 'Female', 'Other', 'Prefer not to say'],
                            (val) {
                              if (_selectedGender == null) {
                                setState(() {
                                  _selectedGender = val;
                                });
                              }
                            },
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _fieldWithLabel(
                            'Age',
                            _ageController,
                            hint: 'e.g., 30',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _dropdownWithLabel(
                            'Gender',
                            _selectedGender,
                            ['Male', 'Female', 'Other', 'Prefer not to say'],
                            (val) {
                              setState(() {
                                _selectedGender = val;
                              });
                            },
                            // No isRequired, no initialValue
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _fieldWithLabel(
                  'Annual Income (₹)',
                  _annualIncomeController,
                  hint: 'e.g., 800000',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
                const SizedBox(height: 18),
                _fieldWithLabel(
                  'Occupation',
                  _occupationController,
                  hint: 'e.g., Software Engineer',
                  isRequired: true,
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 450) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldWithLabel(
                            'Height (cm)',
                            _heightController,
                            hint: 'e.g., 175',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChange: (_) => _calculateBMI(),
                          ),
                          const SizedBox(height: 18),
                          _fieldWithLabel(
                            'Weight (kg)',
                            _weightController,
                            hint: 'e.g., 70',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChange: (_) => _calculateBMI(),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _fieldWithLabel(
                            'Height (cm)',
                            _heightController,
                            hint: 'e.g., 175',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChange: (_) => _calculateBMI(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _fieldWithLabel(
                            'Weight (kg)',
                            _weightController,
                            hint: 'e.g., 70',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChange: (_) => _calculateBMI(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_bmi > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Your calculated BMI: ${_bmi.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _fieldWithLabel(
                  'Location (City, Country)',
                  _locationController,
                  hint: 'e.g., Bangalore, India',
                  isRequired: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyDetailsStep() {
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Family Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tell us about your family situation',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            _dropdownWithLabel(
              'Marital Status',
              _maritalStatus,
              ['Single', 'Married', 'Divorced', 'Widowed'],
              (val) {
                setState(() {
                  _maritalStatus = val;
                });
              },
              isRequired: true,
              initialValue: _maritalStatus,
            ), // Pass initialValue
            const SizedBox(height: 18),
            _fieldWithLabel(
              'Number of Children',
              _numChildrenController,
              hint: 'e.g., 0, 1, 2',
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
            const SizedBox(height: 18),
            _fieldWithLabel(
              'Spouse\'s Annual Income (if applicable)',
              _spouseIncomeController,
              hint: 'e.g., 500000',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthLifestyleStep() {
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Health & Lifestyle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your health and habits influence your premium',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            _dropdownWithLabel(
              'Do you smoke?',
              _smokingHabit,
              ['Yes', 'No'],
              (val) {
                setState(() {
                  _smokingHabit = val;
                });
              },
              isRequired: true,
              initialValue: _smokingHabit,
            ), // Pass initialValue
            const SizedBox(height: 18),
            _dropdownWithLabel(
              'Do you consume alcohol?',
              _drinkingHabit,
              ['Never', 'Occasionally', 'Frequently', 'Daily'],
              (val) {
                setState(() {
                  _drinkingHabit = val;
                });
              },
              isRequired: true,
              initialValue: _drinkingHabit,
            ), // Pass initialValue
            const SizedBox(height: 18),
            _dropdownWithLabel(
              // Changed to single select dropdown
              'Any existing medical conditions?',
              _selectedMedicalCondition,
              [
                'None',
                'Diabetes',
                'Heart Disease',
                'High Blood Pressure',
                'Asthma',
                'Cancer',
              ],
              (val) {
                setState(() {
                  _selectedMedicalCondition = val;
                });
              },
              isRequired: true,
              initialValue: _selectedMedicalCondition,
            ),
            const SizedBox(height: 18),
            _dropdownWithLabel(
              // Changed to single select dropdown
              'Family medical history (e.g., diabetes, heart disease)?',
              _selectedFamilyMedicalCondition,
              [
                'None',
                'Diabetes',
                'Heart Disease',
                'High Blood Pressure',
                'Cancer',
              ],
              (val) {
                setState(() {
                  _selectedFamilyMedicalCondition = val;
                });
              },
              isRequired: true,
              initialValue: _selectedFamilyMedicalCondition,
            ),
            const SizedBox(height: 18),
            _fieldWithLabel(
              'Current Medications (if any)',
              _currentMedicationsController,
              hint: 'e.g., Insulin, Blood Pressure Meds',
            ),
            const SizedBox(height: 18),
            _dropdownWithLabel(
              'How often do you exercise?',
              _exerciseFrequency,
              ['Never', 'Rarely', 'Occasionally', 'Regularly'],
              (val) {
                setState(() {
                  _exerciseFrequency = val;
                });
              },
              initialValue: _exerciseFrequency,
            ), // Pass initialValue
          ],
        ),
      ),
    );
  }

  Widget _buildFinancesCalculationStep() {
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Finances & Preferences',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your financial overview for an accurate calculation and policy preferences',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            _fieldWithLabel(
              'Existing Life Insurance (₹)',
              _existingLifeInsuranceController,
              hint: 'e.g., 0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            _dropdownWithLabel(
              'Preferred Policy Type',
              _policyType,
              [
                'Term Insurance',
                'Whole Life Insurance',
                'ULIP (Unit-Linked)',
                'Endowment',
              ],
              (val) {
                setState(() {
                  _policyType = val;
                });
              },
              isRequired: true,
              initialValue: _policyType,
            ), // Pass initialValue
            const SizedBox(height: 18),
            _dropdownWithLabel(
              // Changed to single select dropdown
              'What are your investment goals (if any)?',
              _selectedInvestmentGoal,
              [
                'None',
                'Wealth Creation',
                'Retirement Planning',
                'Child\'s Education',
                'Capital Preservation',
                'Tax Savings',
              ],
              (val) {
                setState(() {
                  _selectedInvestmentGoal = val;
                });
              },
              isRequired: true,
              initialValue: _selectedInvestmentGoal,
            ),
            const SizedBox(height: 18),
            _fieldWithLabel(
              'Total Debts (e.g., loans, mortgage) (₹)',
              _debtsController,
              hint: 'e.g., 100000',
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
            const SizedBox(height: 18),
            _fieldWithLabel(
              'Total Savings/Investments (₹)',
              _savingsController,
              hint: 'e.g., 50000',
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
            const SizedBox(height: 28),
            Center(
              child: _isSavingCalculation
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (_isCurrentStepValid()) {
                          _calculateInsurance();
                          _nextStep(); // Move to analytics step after calculation
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill all required fields before calculating.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Calculate & View Analytics',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- NEW: Analytics Suggestions Widget ---
  Widget _buildAnalyticsSuggestions() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Colors.purple,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Personalized Analytics',
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
          'Here are insights and suggestions based on your data:',
          style: TextStyle(fontSize: 14, color: subTextColor),
        ),
        const SizedBox(height: 24),

        // Analytics cards in a 2-column layout
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Single column for smaller screens
              return Column(
                children: [
                  _buildAnalyticsCard(
                    icon: Icons.speed,
                    iconColor: Colors.blue.shade600,
                    title: 'Insurance Eligibility',
                    description: _eligibilityOdometerMessage,
                    isLight: isLight,
                    customContent: CustomPaint(
                      size: const Size(200, 100),
                      painter: _EligibilityGaugePainter(
                        eligibilityPercentage: _eligibilityPercentage,
                        isLightMode: isLight,
                      ),
                      child: SizedBox(
                        width: 200,
                        height: 100,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_eligibilityPercentage * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Current Eligibility',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsCardWithChart(
                    icon: Icons.trending_up,
                    iconColor: Colors.green.shade700,
                    title: 'Recommended Coverage Trend',
                    description: _coverageGapMessage,
                    isLight: isLight,
                    chart: CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: _LineChartPainter(
                        data: _coverageTrendData,
                        lineColor: Colors.green.shade400,
                        fillColor: Colors.green.shade100.withOpacity(0.5),
                        isLightMode: isLight,
                      ),
                    ),
                    value: '₹ ${_calculatedInsuranceAmount.toStringAsFixed(0)}',
                    valueColor: Colors.green.shade700,
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsCardWithChart(
                    icon: Icons.shield,
                    iconColor: Colors.orange.shade700,
                    title: 'Risk Profile Breakdown',
                    description: _riskProfileMessage,
                    isLight: isLight,
                    chart: CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: _BarChartPainter(
                        data: _riskFactorData,
                        barColor: Colors.orange.shade400,
                        isLightMode: isLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsCardWithChart(
                    icon: Icons.pie_chart,
                    iconColor: Colors.teal.shade700,
                    title: 'Premium Affordability',
                    description: _premiumAffordabilityMessage,
                    isLight: isLight,
                    chart: CustomPaint(
                      size: const Size(double.infinity, 150),
                      painter: _DonutChartPainter(
                        data: _premiumAllocationData,
                        isLightMode: isLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsCard(
                    icon: Icons.health_and_safety,
                    iconColor: _getMortalityRiskColor(_mortalityRiskMessage),
                    title: 'Mortality Risk Score',
                    description: _mortalityRiskMessage,
                    isLight: isLight,
                    value: _mortalityRiskMessage.split(': ').last,
                    valueColor: _getMortalityRiskColor(_mortalityRiskMessage),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsCardWithChart(
                    icon: Icons.insights,
                    iconColor: Colors.purple.shade700,
                    title: 'Policy Performance Outlook',
                    description: _policyPerformanceMessage,
                    isLight: isLight,
                    chart: CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: _AreaChartPainter(
                        data: _policyGrowthData,
                        lineColor: Colors.purple.shade400,
                        fillColor: Colors.purple.shade100.withOpacity(0.5),
                        isLightMode: isLight,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Two columns for larger screens
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          icon: Icons.speed,
                          iconColor: Colors.blue.shade600,
                          title: 'Insurance Eligibility',
                          description: _eligibilityOdometerMessage,
                          isLight: isLight,
                          customContent: Center(
                            child: CustomPaint(
                              size: const Size(
                                150,
                                75,
                              ), // Smaller gauge for side-by-side
                              painter: _EligibilityGaugePainter(
                                eligibilityPercentage: _eligibilityPercentage,
                                isLightMode: isLight,
                              ),
                              child: SizedBox(
                                width: 150,
                                height: 75,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(_eligibilityPercentage * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        'Eligibility',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subTextColor,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCardWithChart(
                          icon: Icons.trending_up,
                          iconColor: Colors.green.shade700,
                          title: 'Recommended Coverage Trend',
                          description: _coverageGapMessage,
                          isLight: isLight,
                          chart: CustomPaint(
                            size: const Size(double.infinity, 100),
                            painter: _LineChartPainter(
                              data: _coverageTrendData,
                              lineColor: Colors.green.shade400,
                              fillColor: Colors.green.shade100.withOpacity(0.5),
                              isLightMode: isLight,
                            ),
                          ),
                          value:
                              '₹ ${_calculatedInsuranceAmount.toStringAsFixed(0)}',
                          valueColor: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildAnalyticsCardWithChart(
                          icon: Icons.shield,
                          iconColor: Colors.orange.shade700,
                          title: 'Risk Profile Breakdown',
                          description: _riskProfileMessage,
                          isLight: isLight,
                          chart: CustomPaint(
                            size: const Size(double.infinity, 100),
                            painter: _BarChartPainter(
                              data: _riskFactorData,
                              barColor: Colors.orange.shade400,
                              isLightMode: isLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCardWithChart(
                          icon: Icons.pie_chart,
                          iconColor: Colors.teal.shade700,
                          title: 'Premium Affordability',
                          description: _premiumAffordabilityMessage,
                          isLight: isLight,
                          chart: CustomPaint(
                            size: const Size(double.infinity, 150),
                            painter: _DonutChartPainter(
                              data: _premiumAllocationData,
                              isLightMode: isLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          icon: Icons.health_and_safety,
                          iconColor: _getMortalityRiskColor(
                            _mortalityRiskMessage,
                          ),
                          title: 'Mortality Risk Score',
                          description: _mortalityRiskMessage,
                          isLight: isLight,
                          value: _mortalityRiskMessage.split(': ').last,
                          valueColor: _getMortalityRiskColor(
                            _mortalityRiskMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCardWithChart(
                          icon: Icons.insights,
                          iconColor: Colors.purple.shade700,
                          title: 'Policy Performance Outlook',
                          description: _policyPerformanceMessage,
                          isLight: isLight,
                          chart: CustomPaint(
                            size: const Size(double.infinity, 100),
                            painter: _AreaChartPainter(
                              data: _policyGrowthData,
                              lineColor: Colors.purple.shade400,
                              fillColor: Colors.purple.shade100.withOpacity(
                                0.5,
                              ),
                              isLightMode: isLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Helper to get color based on mortality risk message
  Color _getMortalityRiskColor(String message) {
    if (message.contains('High')) return Colors.red.shade700;
    if (message.contains('Medium')) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  // --- Helper Widget for Analytics Cards (without chart) ---
  Widget _buildAnalyticsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    String? value,
    Color? valueColor,
    String? additionalText,
    required bool isLight,
    Widget? customContent, // Added for eligibility gauge
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isLight
          ? Colors.white
          : Colors.grey.shade800, // Consistent card background
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (customContent != null) ...[
              customContent!,
              const SizedBox(height: 16),
            ],
            Text(
              description,
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            if (value != null && customContent == null) ...[
              // Only show value if no custom content
              const SizedBox(height: 8),
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? iconColor,
                  ),
                ),
              ),
            ],
            if (additionalText != null && additionalText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                additionalText,
                style: TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- NEW: Helper Widget for Analytics Cards with Charts ---
  Widget _buildAnalyticsCardWithChart({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Widget chart,
    String? value,
    Color? valueColor,
    String? additionalText,
    required bool isLight,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isLight ? Colors.white : Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            if (value != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? iconColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Chart goes here
            SizedBox(
              height: 150, // Fixed height for charts
              child: chart,
            ),
            if (additionalText != null && additionalText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                additionalText,
                style: TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Reusable TextField with label ---
  Widget _fieldWithLabel(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    bool isRequired = false,
    ValueChanged<String>? onChange, // Added onChange callback
  }) {
    return Column(
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
              Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          onChanged: onChange, // Assign onChange callback
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  // --- Reusable Dropdown with label ---
  Widget _dropdownWithLabel(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    bool isRequired = false,
    String? initialValue, // Added initialValue
  }) {
    return Column(
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
              Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: options
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          hint: Text('Select ${label.toLowerCase()}'),
          onChanged: onChanged,
          validator: isRequired
              ? (val) => val == null || val.isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }
}

// --- Custom Painter for Eligibility Gauge ---
class _EligibilityGaugePainter extends CustomPainter {
  final double eligibilityPercentage;
  final bool isLightMode;

  _EligibilityGaugePainter({
    required this.eligibilityPercentage,
    required this.isLightMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 20.0;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height), // Center at bottom middle
      radius: size.width / 2 - strokeWidth / 2,
    );

    // Background arc (grey)
    paint.shader = null;
    paint.color = isLightMode ? Colors.grey.shade300 : Colors.grey.shade700;
    canvas.drawArc(
      rect,
      pi,
      pi,
      false,
      paint,
    ); // Start at 180 degrees (pi), sweep 180 degrees (pi)

    // Colored arcs with gradients
    // Red zone (0-33%)
    final redGradient = LinearGradient(
      colors: [Colors.red.shade700, Colors.red.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    paint.shader = redGradient.createShader(
      Rect.fromLTWH(0, 0, size.width / 3, size.height),
    );
    canvas.drawArc(
      rect,
      pi,
      min(pi / 3, pi * eligibilityPercentage),
      false,
      paint,
    );

    // Yellow zone (33-66%)
    final yellowGradient = LinearGradient(
      colors: [Colors.orange.shade700, Colors.yellow.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    paint.shader = yellowGradient.createShader(
      Rect.fromLTWH(size.width / 3, 0, size.width / 3, size.height),
    );
    if (pi * eligibilityPercentage > pi / 3) {
      canvas.drawArc(
        rect,
        pi + pi / 3,
        min(pi / 3, pi * eligibilityPercentage - pi / 3),
        false,
        paint,
      );
    }

    // Green zone (66-100%)
    final greenGradient = LinearGradient(
      colors: [Colors.green.shade700, Colors.lightGreen.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    paint.shader = greenGradient.createShader(
      Rect.fromLTWH(2 * size.width / 3, 0, size.width / 3, size.height),
    );
    if (pi * eligibilityPercentage > 2 * pi / 3) {
      canvas.drawArc(
        rect,
        pi + 2 * pi / 3,
        min(pi / 3, pi * eligibilityPercentage - 2 * pi / 3),
        false,
        paint,
      );
    }

    // Needle
    final double needleAngle =
        pi + (pi * eligibilityPercentage); // Start at pi, sweep by percentage
    final double needleLength = size.width / 2 - strokeWidth;
    final Offset center = Offset(size.width / 2, size.height);
    final Offset needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    paint.shader = null;
    paint.color = isLightMode ? Colors.black : Colors.white;
    paint.strokeWidth = 3.0;
    canvas.drawLine(center, needleEnd, paint);

    // Central dot for needle pivot
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.0, paint);
  }

  @override
  bool shouldRepaint(covariant _EligibilityGaugePainter oldDelegate) {
    return oldDelegate.eligibilityPercentage != eligibilityPercentage ||
        oldDelegate.isLightMode != isLightMode;
  }
}

// --- NEW: Custom Painter for Line Chart ---
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final bool isLightMode;

  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.isLightMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxData = data.reduce(max);
    final double minData = data.reduce(min);
    final double range = maxData - minData;

    final Path linePath = Path();
    final Path fillPath = Path();

    // Calculate scaling factors
    final double xStep = size.width / (data.length - 1);
    final double yScaler =
        size.height / (range == 0 ? 1 : range); // Avoid division by zero

    // Move to the first point
    linePath.moveTo(0, size.height - (data[0] - minData) * yScaler);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - (data[0] - minData) * yScaler);

    // Draw lines and fill path
    for (int i = 1; i < data.length; i++) {
      final double x = i * xStep;
      final double y = size.height - (data[i] - minData) * yScaler;
      linePath.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(
      size.width,
      size.height,
    ); // Close the fill path at the bottom right
    fillPath.close();

    // Draw fill area
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Draw data points (circles)
    final Paint pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = lineColor;
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      final double y = size.height - (data[i] - minData) * yScaler;
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.isLightMode != isLightMode;
  }
}

// --- NEW: Custom Painter for Bar Chart ---
class _BarChartPainter extends CustomPainter {
  final Map<String, double> data; // Data is now a map for labels
  final Color barColor;
  final bool isLightMode;

  _BarChartPainter({
    required this.data,
    required this.barColor,
    required this.isLightMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxData = data.values.reduce(max);
    final double barWidth =
        (size.width / data.length) * 0.6; // 60% width, 40% spacing
    final double spacing =
        (size.width / data.length) *
        0.4 /
        (data.length - 1).clamp(1, data.length); // Distribute remaining space

    double currentX = spacing / 2; // Start with half spacing

    for (var entry in data.entries) {
      final double barHeight = (entry.value / maxData) * size.height;
      final Rect barRect = Rect.fromLTWH(
        currentX,
        size.height - barHeight,
        barWidth,
        barHeight,
      );

      final Paint barPaint = Paint()..color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
        barPaint,
      );

      // Draw label below bar
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: isLightMode ? Colors.grey.shade700 : Colors.grey.shade300,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          currentX + (barWidth / 2) - (textPainter.width / 2),
          size.height + 5,
        ),
      );

      currentX += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.barColor != barColor ||
        oldDelegate.isLightMode != isLightMode;
  }
}

// --- NEW: Custom Painter for Donut Chart ---
class _DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final bool isLightMode;

  _DonutChartPainter({required this.data, required this.isLightMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double total = data.values.fold(0.0, (sum, item) => sum + item);
    if (total == 0) return; // Avoid division by zero

    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double strokeWidth = radius * 0.4; // Donut thickness

    double startAngle = 0.0;
    final List<Color> colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];

    int colorIndex = 0;
    for (var entry in data.entries) {
      final double sweepAngle = (entry.value / total) * 2 * pi;
      final Paint segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = colors[colorIndex % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );

      // Draw text label next to the donut (optional, can be in a legend)
      final double midAngle = startAngle + sweepAngle / 2;
      final double textRadius = radius + 10; // Position text slightly outside
      final Offset textPosition = Offset(
        center.dx + textRadius * cos(midAngle),
        center.dy + textRadius * sin(midAngle),
      );

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '${(entry.value * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: isLightMode ? Colors.black : Colors.white,
            fontSize: 10,
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

    // Draw central text (e.g., "Total")
    final TextPainter centerTextPainter = TextPainter(
      text: TextSpan(
        text: 'Total\n${total.toStringAsFixed(0)}',
        style: TextStyle(
          color: isLightMode ? Colors.grey.shade700 : Colors.grey.shade300,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    centerTextPainter.paint(
      canvas,
      center -
          Offset(centerTextPainter.width / 2, centerTextPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isLightMode != isLightMode;
  }
}

// --- NEW: Custom Painter for Area Chart ---
class _AreaChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final bool isLightMode;

  _AreaChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.isLightMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxData = data.reduce(max);
    final double minData = data.reduce(min);
    final double range = maxData - minData;

    final Path path = Path();

    // Scale data to fit the canvas height
    final double xStep = size.width / (data.length - 1);
    final double yScaler = size.height / (range == 0 ? 1 : range);

    // Start path at bottom-left
    path.moveTo(0, size.height);
    path.lineTo(0, size.height - (data[0] - minData) * yScaler);

    // Draw line and fill area
    for (int i = 1; i < data.length; i++) {
      final double x = i * xStep;
      final double y = size.height - (data[i] - minData) * yScaler;
      path.lineTo(x, y);
    }

    // Close path at bottom-right
    path.lineTo(size.width, size.height);
    path.close();

    // Draw fill area
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    canvas.drawPath(path, fillPaint);

    // Draw line
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw data points (optional)
    final Paint pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = lineColor;
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      final double y = size.height - (data[i] - minData) * yScaler;
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.isLightMode != isLightMode;
  }
}
