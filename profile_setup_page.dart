import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // For input formatters
import 'package:image_picker/image_picker.dart'; // For image/file picking
import 'dart:typed_data'; // For Uint8List (image data)

class ProfileSetupPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentThemeMode;

  const ProfileSetupPage({
    Key? key,
    required this.toggleTheme,
    required this.currentThemeMode,
  }) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false; // For saving profile
  bool _isFetchingProfile = true; // For loading existing profile
  String? _errorMessage;
  String? _fetchProfileError; // To show error if profile fetch fails

  final String _backendBaseUrl = 'http://localhost:3000';

  // --- Session 1: Personal Identity and Address Information ---
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'Prefer not to say'; // Default
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  String? _addressProofType; // e.g., Passport, Voter ID
  final TextEditingController _addressProofDetailsController =
      TextEditingController();
  Uint8List? _photographIpvBytes; // For storing Base64 image data

  // --- Session 2: Financial Information ---
  final TextEditingController _bankAccountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  String? _annualSalaryRange; // e.g., "1 Lakh - 3 Lakh"
  Uint8List? _incomeProofBytes; // For storing Base64 file data
  final TextEditingController _creditScoreController = TextEditingController();

  // --- Session 3: Background and Contact Information ---
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailIdController =
      TextEditingController(); // Firebase handles primary email, but for display/secondary
  String? _occupation; // Dropdown
  final TextEditingController _otherOccupationController =
      TextEditingController(); // If 'Other' is selected
  String? _educationalQualification; // Dropdown
  bool _addNominee = false;
  final TextEditingController _nomineeNameController = TextEditingController();
  final TextEditingController _nomineeMobileController =
      TextEditingController();
  final TextEditingController _nomineeEmailController = TextEditingController();

  // --- Session 4: Device Information and Permissions (Explanatory) ---
  // No controllers needed, just explanatory text.

  // --- Session 5: Terms & Conditions & Consent ---
  bool _agreedToTerms = false;
  bool _consentCallSmsEmail = false;
  bool _consentWhatsapp = false;
  bool _bypassSuitabilityAnalysis = false;
  Widget _buildPage(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
    _fetchUserProfile(); // Fetch profile when the page initializes
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _addressProofDetailsController.dispose();
    _bankAccountNumberController.dispose();
    _ifscCodeController.dispose();
    _creditScoreController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    _otherOccupationController.dispose();
    _nomineeNameController.dispose();
    _nomineeMobileController.dispose();
    _nomineeEmailController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // Method to fetch user profile from the backend
  Future<void> _fetchUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isFetchingProfile = false;
        _fetchProfileError = 'No authenticated user found.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/api/profile/${user.uid}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          // Session 1
          _firstNameController.text = data['first_name'] ?? '';
          _middleNameController.text = data['middle_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _dateOfBirth = data['date_of_birth'] != null
              ? DateTime.tryParse(data['date_of_birth'])
              : null;
          _gender = data['gender'] ?? 'Prefer not to say';
          _panController.text = data['pan_card'] ?? '';
          _aadhaarController.text = data['aadhaar_card'] ?? '';
          _addressProofType = data['address_proof_type'];
          _addressProofDetailsController.text =
              data['address_proof_details'] ?? '';
          _photographIpvBytes = data['photograph_ipv'] != null
              ? base64Decode(data['photograph_ipv'])
              : null;

          // Session 2
          _bankAccountNumberController.text = data['bank_account_number'] ?? '';
          _ifscCodeController.text = data['ifsc_code'] ?? '';
          _annualSalaryRange = data['annual_salary_range'];
          _incomeProofBytes = data['income_proof'] != null
              ? base64Decode(data['income_proof'])
              : null;
          _creditScoreController.text = (data['credit_score'] ?? '').toString();

          // Session 3
          _mobileNumberController.text = data['mobile_number'] ?? '';
          _emailIdController.text =
              data['email_id'] ??
              user.email ??
              ''; // Pre-fill with Firebase email
          _occupation = data['occupation'];
          if (_occupation == 'Other') {
            _otherOccupationController.text = data['other_occupation'] ?? '';
          }
          _educationalQualification = data['educational_qualification'];
          _addNominee = data['add_nominee'] ?? false;
          _nomineeNameController.text = data['nominee_name'] ?? '';
          _nomineeMobileController.text = data['nominee_mobile'] ?? '';
          _nomineeEmailController.text = data['nominee_email'] ?? '';

          // Session 5
          _agreedToTerms = data['agreed_to_terms'] ?? false;
          _consentCallSmsEmail = data['consent_call_sms_email'] ?? false;
          _consentWhatsapp = data['consent_whatsapp'] ?? false;
          _bypassSuitabilityAnalysis =
              data['bypass_suitability_analysis'] ?? false;

          _isFetchingProfile = false;
        });
      } else if (response.statusCode == 404) {
        // Profile not found, normal for new users. Clear any errors.
        setState(() {
          _isFetchingProfile = false;
          _fetchProfileError = null;
          _emailIdController.text =
              user.email ?? ''; // Pre-fill email if new user
        });
      } else {
        setState(() {
          _isFetchingProfile = false;
          _fetchProfileError =
              'Failed to load profile: ${response.statusCode} - ${response.body}';
        });
        print(
          'Backend error fetching profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _isFetchingProfile = false;
        _fetchProfileError =
            'Network error: ${e.toString()}. Is backend running?';
      });
      print('Network error fetching profile: $e');
    }
  }

  // NEW: Validation for current session
  bool _isCurrentSessionValid() {
    // We'll use a Form widget with GlobalKey for validation on each page.
    // For now, this checks if controllers have text and dropdowns have values.
    switch (_currentPage) {
      case 0: // Session 1: Personal Identity and Address Information
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _dateOfBirth != null &&
            _panController.text.replaceAll(' ', '').length == 10 &&
            _aadhaarController.text.replaceAll(' ', '').length == 12 &&
            _addressProofType != null &&
            _addressProofDetailsController.text.isNotEmpty &&
            _photographIpvBytes != null;
      case 1: // Session 2: Financial Information
        return _bankAccountNumberController.text.isNotEmpty &&
            _ifscCodeController.text.isNotEmpty &&
            _annualSalaryRange != null &&
            _creditScoreController.text.isNotEmpty &&
            (int.tryParse(_creditScoreController.text) ?? 0) >= 300 &&
            (int.tryParse(_creditScoreController.text) ?? 0) <= 900;
      case 2: // Session 3: Background and Contact Information
        return _mobileNumberController.text.replaceAll(' ', '').length == 10 &&
            _emailIdController.text.isNotEmpty &&
            _occupation != null &&
            (_occupation != 'Other' ||
                _otherOccupationController.text.isNotEmpty) &&
            _educationalQualification != null &&
            (!_addNominee ||
                (_nomineeNameController.text.isNotEmpty &&
                    _nomineeMobileController.text.replaceAll(' ', '').length ==
                        10 &&
                    _nomineeEmailController.text.isNotEmpty));
      case 3: // Session 4: Device Information and Permissions (Explanatory page, no mandatory fields)
        return true;
      case 4: // Session 5: Terms & Conditions & Consent (Validation for this is handled by _agreedToTerms and specific checkboxes)
        return true; // Actual validation for final submission is in _saveProfileAndNavigate
      default:
        return false;
    }
  }

  void _nextPage() {
    if (!_isCurrentSessionValid()) {
      _showSnackBar(
        'Please fill all required fields in the current section.',
        Colors.orange,
      );
      return;
    }
    if (_currentPage < 4) {
      // Total 5 pages (0-4)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickFile(Function(Uint8List?) onPicked) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker
        .pickMedia(); // pickMedia allows any file type

    if (file != null) {
      final Uint8List bytes = await file.readAsBytes();
      setState(() {
        onPicked(bytes);
      });
    } else {
      _showSnackBar('No file selected.', Colors.red);
    }
  }

  Future<void> _saveProfileAndNavigate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('No user logged in.', Colors.red);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!_agreedToTerms) {
      _showSnackBar(
        'Please agree to the terms and conditions to proceed.',
        Colors.orange,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    // Final check for suitability analysis bypass checkbox
    if (!_bypassSuitabilityAnalysis &&
        (_consentCallSmsEmail || _consentWhatsapp)) {
      _showSnackBar(
        'To undergo suitability analysis, please click the link provided. If you wish to bypass, please check the bypass checkbox.',
        Colors.orange,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Ensure all previous sessions are valid before final save
    if (!_isCurrentSessionValid()) {
      // This check is for the last displayed session before T&C
      _showSnackBar(
        'Please complete all required fields in the previous sections.',
        Colors.orange,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firebase_uid': user.uid,
          // Session 1
          'first_name': _firstNameController.text,
          'middle_name': _middleNameController.text.isEmpty
              ? null
              : _middleNameController.text,
          'last_name': _lastNameController.text,
          'date_of_birth': _dateOfBirth?.toIso8601String(),
          'gender': _gender,
          'pan_card': _panController.text.replaceAll(
            ' ',
            '',
          ), // Remove spaces for storage
          'aadhaar_card': _aadhaarController.text.replaceAll(
            ' ',
            '',
          ), // Remove spaces for storage
          'address_proof_type': _addressProofType,
          'address_proof_details': _addressProofDetailsController.text,
          'photograph_ipv': _photographIpvBytes != null
              ? base64Encode(_photographIpvBytes!)
              : null,

          // Session 2
          'bank_account_number': _bankAccountNumberController.text,
          'ifsc_code': _ifscCodeController.text,
          'annual_salary_range': _annualSalaryRange,
          'income_proof': _incomeProofBytes != null
              ? base64Encode(_incomeProofBytes!)
              : null,
          'credit_score': int.tryParse(_creditScoreController.text),

          // Session 3
          'mobile_number': _mobileNumberController.text,
          'email_id': _emailIdController.text,
          'occupation': _occupation,
          'other_occupation': _occupation == 'Other'
              ? _otherOccupationController.text
              : null,
          'educational_qualification': _educationalQualification,
          'add_nominee': _addNominee,
          'nominee_name': _addNominee ? _nomineeNameController.text : null,
          'nominee_mobile': _addNominee ? _nomineeMobileController.text : null,
          'nominee_email': _addNominee ? _nomineeEmailController.text : null,

          // Session 5
          'agreed_to_terms': _agreedToTerms,
          'consent_call_sms_email': _consentCallSmsEmail,
          'consent_whatsapp': _consentWhatsapp,
          'bypass_suitability_analysis': _bypassSuitabilityAnalysis,
          'setupComplete': true,
          'lastUpdated': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar(
          'Profile setup complete! Welcome to MyFin!',
          Colors.green,
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(
          'Error saving profile: ${errorData['error'] ?? 'Unknown error'}',
          Colors.red,
        );
        print('Backend error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar(
        'An unexpected error occurred: ${e.toString()}. Is backend running?',
        Colors.red,
      );
      print('Network error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
                color: Theme.of(context).iconTheme.color,
              )
            : null,
      ),
      body: _isFetchingProfile
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : _fetchProfileError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _fetchProfileError!,
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 5, // 5 pages (0-4)
                    backgroundColor: Theme.of(
                      context,
                    ).dividerColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
                Expanded(
                  child: Center( // Added Center and ConstrainedBox for overall page width
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600), 
                          child: Container( // NEW: Added Container here
                            decoration: BoxDecoration( // NEW: Decoration for the border
                              color: Theme.of(context).cardColor, // Use cardColor for background
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.5), // Border color
                                width: 1,
                              ),
                            ),// Max width for content
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Session 1: Personal Identity and Address Information
                      _buildPage(
                        context,
                        title: 'Your Identity & Address',
                        subtitle:
                            'Let\'s verify who you are and where you live.',
                        icon: Icons.badge,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 450) {
                                return Column(
                                  children: [
                                    _buildTextField(
                                      controller: _firstNameController,
                                      label: 'First Name',
                                      hint: 'John',
                                      isMandatory: true,
                                      onChanged: (value) => setState(() {}),
                                    ), // Corrected onChanged
                                    const SizedBox(height: 18),
                                    _buildTextField(
                                      controller: _middleNameController,
                                      label: 'Middle Name (Optional)',
                                      hint: 'M',
                                      onChanged: (value) => setState(() {}),
                                    ), // Corrected onChanged
                                    const SizedBox(height: 18),
                                    _buildTextField(
                                      controller: _lastNameController,
                                      label: 'Last Name',
                                      hint: 'Doe',
                                      isMandatory: true,
                                      onChanged: (value) => setState(() {}),
                                    ), // Corrected onChanged
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _firstNameController,
                                      label: 'First Name',
                                      hint: 'John',
                                      isMandatory: true,
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ), // Corrected onChanged
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _middleNameController,
                                      label: 'Middle Name (Optional)',
                                      hint: 'M',
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ), // Corrected onChanged
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _lastNameController,
                                      label: 'Last Name',
                                      hint: 'Doe',
                                      isMandatory: true,
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ), // Corrected onChanged
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildDatePickerField(
                            context,
                            label: 'Date of Birth',
                            selectedDate: _dateOfBirth,
                            isMandatory: true,
                            onChanged: (date) =>
                                setState(() => _dateOfBirth = date),
                          ),
                          const SizedBox(height: 18),
                          _buildDropdownField(
                            label: 'Gender',
                            value: _gender,
                            items: ['Male', 'Female', 'Prefer not to say'],
                            onChanged: (value) =>
                                setState(() => _gender = value!),
                            isMandatory: true,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _panController,
                            label: 'PAN Card Number',
                            hint: 'ABCDE1234F',
                            icon: Icons.credit_card,
                            isMandatory: true,
                            textCapitalization: TextCapitalization.characters,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(10),
                              // PanInputFormatter(), // Custom formatter for visual masking
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'PAN is mandatory';
                              if (!RegExp(
                                r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
                              ).hasMatch(value.replaceAll(' ', '')))
                                return 'Invalid PAN format';
                              return null;
                            },
                            onChanged: (value) =>
                                setState(() {}), // Corrected onChanged
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _aadhaarController,
                            label: 'Aadhaar Card Number',
                            hint: 'XXXX XXXX XXXX',
                            icon: Icons.fingerprint,
                            isMandatory: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                              // AadhaarInputFormatter(), // Custom formatter for visual masking
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Aadhaar is mandatory';
                              if (!RegExp(
                                r'^\d{12}$',
                              ).hasMatch(value.replaceAll(' ', '')))
                                return 'Invalid Aadhaar format';
                              return null;
                            },
                            onChanged: (value) =>
                                setState(() {}), // Corrected onChanged
                          ),
                          const SizedBox(height: 18),
                          _buildDropdownField(
                            label: 'Proof of Address Type',
                            value: _addressProofType,
                            items: [
                              'Passport',
                              'Voter ID',
                              'Driving License',
                              'Utility Bill (last 3 months)',
                            ],
                            onChanged: (value) => setState(() {
                              _addressProofType = value!;
                              // Clear details when type changes
                              _addressProofDetailsController.clear();
                            }),
                            isMandatory: true,
                          ),
                          const SizedBox(height: 18),
                          // Conditional Address Proof Details field
                          if (_addressProofType != null)
                            _buildAddressProofDetailsField(
                              context,
                            ), // Calling the new method
                          const SizedBox(height: 18),
                          _buildFileUploadField(
                            context,
                            label: 'Photograph (for IPV)',
                            buttonText: _photographIpvBytes != null
                                ? 'Change Photo'
                                : 'Upload Photo',
                            icon: Icons.camera_alt,
                            isMandatory: true,
                            onPicked: (bytes) =>
                                setState(() => _photographIpvBytes = bytes),
                            currentFileBytes: _photographIpvBytes,
                          ),
                        ],
                      ),

                      // Session 2: Financial Information
                      _buildPage(
                        context,
                        title: 'Your Financial World',
                        subtitle:
                            'Securely link your finances for personalized insights.',
                        icon: Icons.account_balance_wallet,
                        children: [
                          _buildTextField(
                            controller: _bankAccountNumberController,
                            label: 'Bank Account Number',
                            hint: 'e.g., 123456789012',
                            icon: Icons.account_balance,
                            isMandatory: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Bank Account Number is mandatory';
                              if (value.length < 9 || value.length > 18)
                                return 'Invalid account number length'; // Common range
                              return null;
                            },
                            onChanged: (value) =>
                                setState(() {}), // Corrected onChanged
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _ifscCodeController,
                            label: 'IFSC Code',
                            hint: 'ABCD0123456',
                            icon: Icons.code,
                            isMandatory: true,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'IFSC Code is mandatory';
                              if (!RegExp(
                                r'^[A-Z]{4}0[A-Z0-9]{6}$',
                              ).hasMatch(value))
                                return 'Invalid IFSC format';
                              return null;
                            },
                            onChanged: (value) =>
                                setState(() {}), // Corrected onChanged
                          ),
                          const SizedBox(height: 18),
                          _buildDropdownField(
                            label: 'Annual Salary Range',
                            value: _annualSalaryRange,
                            items: [
                              'Below ₹1 Lakh',
                              '₹1 Lakh - ₹3 Lakh',
                              '₹3 Lakh - ₹5 Lakh',
                              '₹5 Lakh - ₹10 Lakh',
                              '₹10 Lakh - ₹25 Lakh',
                              '₹25 Lakh - ₹50 Lakh',
                              'Above ₹50 Lakh',
                            ],
                            onChanged: (value) =>
                                setState(() => _annualSalaryRange = value!),
                            isMandatory: true,
                          ),
                          const SizedBox(height: 18),
                          _buildFileUploadField(
                            context,
                            label: 'Income Proof (Optional)',
                            buttonText: _incomeProofBytes != null
                                ? 'Change Proof'
                                : 'Upload Income Proof',
                            icon: Icons.attach_file,
                            isMandatory: false,
                            onPicked: (bytes) =>
                                setState(() => _incomeProofBytes = bytes),
                            currentFileBytes: _incomeProofBytes,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _creditScoreController,
                            label: 'Credit Score (e.g., CIBIL, Experian)',
                            hint: 'e.g., 750',
                            icon: Icons.score,
                            isMandatory: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Credit Score is mandatory';
                              final score = int.tryParse(value);
                              if (score == null || score < 300 || score > 900)
                                return 'Score must be between 300-900';
                              return null;
                            },
                            onChanged: (value) =>
                                setState(() {}), // Corrected onChanged
                          ),
                        ],
                      ),

                      // Session 3: Background and Contact Information
                      _buildPage(
                        context,
                        title: 'Your Background & Connect',
                        subtitle:
                            'How we can reach you and understand your professional path.',
                        icon: Icons.contact_mail,
                        children: [
                          _buildTextField(
                            controller: _mobileNumberController,
                            label: 'Mobile Number',
                            hint: 'e.g., 9876543210',
                            icon: Icons.phone,
                            isMandatory: true,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Mobile Number is mandatory';
                              if (value.length != 10)
                                return 'Mobile Number must be 10 digits';
                              return null;
                            },
                            onChanged: (value) =>
                                setState(() {}), // Corrected onChanged
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _emailIdController,
                            label: 'Email ID',
                            hint: 'your.email@example.com',
                            icon: Icons.email,
                            isMandatory: true,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Email ID is mandatory';
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value))
                                return 'Enter a valid email';
                              return null;
                            },
                            onChanged: (value) =>
                                setState(() {}), // Corrected onChanged
                          ),
                          const SizedBox(height: 18),
                          _buildDropdownField(
                            label: 'Occupation',
                            value: _occupation,
                            items: [
                              'Salaried',
                              'Self-Employed',
                              'Business Owner',
                              'Student',
                              'Homemaker',
                              'Retired',
                              'Other',
                            ],
                            onChanged: (value) => setState(() {
                              _occupation = value!;
                              if (value != 'Other')
                                _otherOccupationController.clear();
                            }),
                            isMandatory: true,
                          ),
                          if (_occupation == 'Other')
                            Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: _buildTextField(
                                controller: _otherOccupationController,
                                label: 'Specify Other Occupation',
                                hint: 'e.g., Freelancer',
                                icon: Icons.work,
                                isMandatory: true,
                                onChanged: (value) =>
                                    setState(() {}), // Corrected onChanged
                              ),
                            ),
                          const SizedBox(height: 18),
                          _buildDropdownField(
                            label: 'Educational Qualification',
                            value: _educationalQualification,
                            items: [
                              'Below High School',
                              'High School',
                              'Diploma',
                              'Graduate',
                              'Post Graduate',
                              'Doctorate',
                            ],
                            onChanged: (value) => setState(
                              () => _educationalQualification = value!,
                            ),
                            isMandatory: true,
                          ),
                          const SizedBox(height: 24),
                          Card(
                            elevation: 1,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                'Nominee Details (Optional)',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              leading: Icon(
                                Icons.group_add,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onExpansionChanged: (expanded) =>
                                  setState(() => _addNominee = expanded),
                              initiallyExpanded: _addNominee,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _nomineeNameController,
                                        label: 'Nominee Full Name',
                                        hint: 'Jane Doe',
                                        icon: Icons.person_outline,
                                        onChanged: (value) => setState(
                                          () {},
                                        ), // Corrected onChanged
                                      ),
                                      const SizedBox(height: 18),
                                      _buildTextField(
                                        controller: _nomineeMobileController,
                                        label: 'Nominee Mobile Number',
                                        hint: 'e.g., 9876543210',
                                        icon: Icons.phone,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        onChanged: (value) => setState(
                                          () {},
                                        ), // Corrected onChanged
                                      ),
                                      const SizedBox(height: 18),
                                      _buildTextField(
                                        controller: _nomineeEmailController,
                                        label: 'Nominee Email ID',
                                        hint: 'jane.doe@example.com',
                                        icon: Icons.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        onChanged: (value) => setState(
                                          () {},
                                        ), // Corrected onChanged
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Session 4: Device Information and Permissions (Explanatory)
                      _buildPage(
                        context,
                        title: 'Device Permissions & Security',
                        subtitle:
                            'Understanding how MyFin uses device features for your security.',
                        icon: Icons.security,
                        children: [
                          _buildPermissionInfoCard(
                            context,
                            icon: Icons.location_on,
                            title: 'Location Access',
                            description:
                                'Used to confirm your location during In-Person Verification (IPV) and for regulatory geotagging requirements. This helps prevent fraud and ensures compliance.',
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionInfoCard(
                            context,
                            icon: Icons.folder_open,
                            title: 'Storage Access',
                            description:
                                'Needed to access and upload your required KYC documents (e.g., PAN, Aadhaar, Income Proof) from your device\'s storage.',
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionInfoCard(
                            context,
                            icon: Icons.camera_alt,
                            title: 'Camera Access',
                            description:
                                'Required for capturing your photograph during In-Person Verification (IPV) and for scanning documents directly within the app.',
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Note: For native mobile apps, you will be prompted to grant these permissions. For web, browser permissions are handled automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),

                      // Session 5: Terms & Conditions
                      _buildPage(
                        context,
                        title: 'Your Privacy Matters',
                        subtitle:
                            'Please review our commitment to your data security.',
                        icon: Icons.lock,
                        children: [
                          Text(
                            // Removed SingleChildScrollView here
                            _termsAndConditionsText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Communication Consent Checkboxes
                          _buildConsentCheckbox(
                            label:
                                'I\'m ready to receive Call, SMS, Email communications',
                            value: _consentCallSmsEmail,
                            onChanged: (newValue) => setState(
                              () => _consentCallSmsEmail = newValue ?? false,
                            ),
                          ),
                          _buildConsentCheckbox(
                            label:
                                'I\'m ready to receive Voice over Internet Protocol including WhatsApp communications',
                            value: _consentWhatsapp,
                            onChanged: (newValue) => setState(
                              () => _consentWhatsapp = newValue ?? false,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Suitability Analysis Bypass Checkbox
                          _buildConsentCheckbox(
                            label:
                                'By selecting this, you declare to consciously bypass the recommended suitability module and purchase the policy based on your independent assessment.',
                            value: _bypassSuitabilityAnalysis,
                            onChanged: (newValue) => setState(
                              () => _bypassSuitabilityAnalysis =
                                  newValue ?? false,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _agreedToTerms = newValue ?? false;
                                  });
                                },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                              Expanded(
                                // Re-added Expanded here for the Text, as it's within a Row
                                child: Text(
                                  'I agree to the terms and conditions regarding data privacy.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                   ), ),),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentPage > 0 && _currentPage < 4)
                        const SizedBox(width: 16),
                      if (_currentPage < 4)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCurrentSessionValid()
                                ? _nextPage
                                : null, // Disable if not valid
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Next'),
                          ),
                        )
                      else
                        Expanded(
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed:
                                      _agreedToTerms && _isCurrentSessionValid()
                                      ? _saveProfileAndNavigate
                                      : null, // Disable if not agreed or last session not valid
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Agree & Finish Setup'),
                                ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- NEW: Conditional Address Proof Details Field ---
  Widget _buildAddressProofDetailsField(BuildContext context) {
    String labelText = 'Address Proof Details';
    String hintText = 'Enter details for selected proof';
    TextInputType keyboardType = TextInputType.text;
    List<TextInputFormatter>? inputFormatters;
    String? Function(String?)? validator;
    // int? maxLength; // Not directly used here, handled by inputFormatters

    switch (_addressProofType) {
      case 'Passport':
        labelText = 'Passport Number';
        hintText = 'e.g., M1234567';
        inputFormatters = [
          LengthLimitingTextInputFormatter(9),
        ]; // Example length
        validator = (value) {
          if (value == null || value.isEmpty)
            return 'Passport Number is mandatory';
          if (value.length != 9) return 'Passport Number must be 9 characters';
          return null;
        };
        break;
      case 'Voter ID':
        labelText = 'Voter ID Number';
        hintText = 'e.g., ABC1234567';
        inputFormatters = [
          LengthLimitingTextInputFormatter(10),
        ]; // Example length
        validator = (value) {
          if (value == null || value.isEmpty)
            return 'Voter ID Number is mandatory';
          if (value.length != 10)
            return 'Voter ID Number must be 10 characters';
          return null;
        };
        break;
      case 'Driving License':
        labelText = 'Driving License Number';
        hintText = 'e.g., DL1234567890';
        inputFormatters = [
          LengthLimitingTextInputFormatter(16),
        ]; // Example length
        validator = (value) {
          if (value == null || value.isEmpty)
            return 'Driving License Number is mandatory';
          // Basic check, actual DL formats vary
          if (value.length < 10 || value.length > 16)
            return 'Invalid Driving License length';
          return null;
        };
        break;
      case 'Utility Bill (last 3 months)':
        labelText = 'Utility Bill Account Number';
        hintText = 'e.g., Electricity Bill Account No.';
        keyboardType = TextInputType.number;
        inputFormatters = [FilteringTextInputFormatter.digitsOnly];
        validator = (value) {
          if (value == null || value.isEmpty)
            return 'Utility Bill Account Number is mandatory';
          return null;
        };
        break;
      default:
        labelText = 'Address Proof Details';
        hintText = 'Enter details for selected proof';
        break;
    }

    return _buildTextField(
      controller: _addressProofDetailsController,
      label: labelText,
      hint: hintText,
      icon: Icons.description,
      isMandatory: true,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: (value) => setState(() {}), // Corrected onChanged
    );
  }

  // --- Reusable TextField with label and validation ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required ValueChanged<String> onChanged,
    bool isMandatory = false,
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
            if (isMandatory)
              Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged:
              onChanged, // This is the line that needs to be passed correctly
          validator: validator,
          autovalidateMode:
              AutovalidateMode.onUserInteraction, // Validate as user types
        ),
      ],
    );
  }

  // --- Reusable Dropdown with label and validation ---
  Widget _buildDropdownField({
    required String label,
    String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
    bool isMandatory = false,
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
            if (isMandatory)
              Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          hint: Text(
            'Select ${label.toLowerCase()}',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          onChanged: onChanged,
          validator: isMandatory
              ? (val) =>
                    val == null || val.isEmpty || val == 'Prefer not to say'
                    ? 'Required'
                    : null
              : null,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ],
    );
  }

  // --- Reusable Date Picker Field ---
  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onChanged,
    bool isMandatory = false,
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
            if (isMandatory)
              Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: selectedDate != null
                ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                : '',
          ),
          decoration: InputDecoration(
            hintText: 'Select Date',
            prefixIcon: const Icon(Icons.calendar_today),
            // FIX: Removed default border to prevent stray lines
            border: InputBorder
                .none, // Changed from OutlineInputBorder to InputBorder.none
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme:
                        Theme.of(context).brightness == Brightness.light
                        ? ColorScheme.light(
                            primary: Theme.of(
                              context,
                            ).primaryColor, // Header background color
                            onPrimary: Colors.white, // Header text color
                            surface: Theme.of(
                              context,
                            ).cardColor, // Date picker background
                            onSurface:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.black, // Body text color
                          )
                        : ColorScheme.dark(
                            primary: Theme.of(
                              context,
                            ).primaryColor, // Header background color
                            onPrimary: Colors.white, // Header text color
                            surface: Theme.of(
                              context,
                            ).cardColor, // Date picker background
                            onSurface:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.white, // Body text color
                          ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).primaryColor, // Button text color
                      ),
                    ),
                    // NEW: Explicitly set dialog background to match theme for dark mode
                    dialogBackgroundColor: Theme.of(context).cardColor,
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null && pickedDate != selectedDate) {
              onChanged(pickedDate);
            }
          },
          validator: isMandatory
              ? (value) => value == null || value.isEmpty ? 'Required' : null
              : null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  // --- Reusable File Upload Field ---
  Widget _buildFileUploadField(
    BuildContext context, {
    required String label,
    required String buttonText,
    required IconData icon,
    required ValueChanged<Uint8List?> onPicked,
    Uint8List? currentFileBytes,
    bool isMandatory = false,
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
            if (isMandatory)
              Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentFileBytes != null
                      ? 'File selected (${(currentFileBytes.length / 1024).toStringAsFixed(1)} KB)'
                      : 'No file chosen',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () =>
                    _pickFile(onPicked), // Use _pickFile for general files
                child: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isMandatory && currentFileBytes == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Required',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // --- Permission Info Card (for Session 4) ---
  Widget _buildPermissionInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Goal Selection Field (from previous version) ---
  Widget _buildGoalSelectionField(
    BuildContext context, {
    required String label,
    required List<String> selectedGoals,
    required ValueChanged<List<String>> onChanged,
  }) {
    final List<String> availableGoals = [
      'Retirement Planning',
      'Child\'s Education',
      'Home Purchase',
      'Car Purchase',
      'Travel',
      'Debt Reduction',
      'Wealth Creation',
      'Emergency Fund',
      'Early Retirement',
      'Starting a Business',
      'Other',
    ];

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.star),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: availableGoals.map((goal) {
          final isSelected = selectedGoals.contains(goal);
          return FilterChip(
            label: Text(goal),
            selected: isSelected,
            onSelected: (selected) {
              List<String> updatedGoals = List.from(selectedGoals);
              if (selected) {
                updatedGoals.add(goal);
              } else {
                updatedGoals.remove(goal);
              }
              onChanged(updatedGoals);
            },
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
            checkmarkColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // NEW: Consent Checkbox Helper
  Widget _buildConsentCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final String _termsAndConditionsText = """
By proceeding, you agree to allow MyFin to collect and use the information provided for the sole purpose of generating personalized financial insights, recommendations, and reports within the MyFin application.

**Data Privacy Commitment:**
* **Confidentiality:** Your personal and financial data will be kept strictly confidential.
* **Security:** We employ industry-standard security measures to protect your data from unauthorized access, disclosure, alteration, or destruction.
* **No Sharing:** Your individual data will NOT be shared, sold, or rented to any third parties for marketing or any other purposes without your explicit consent.
* **Anonymized Use:** Aggregated and anonymized data may be used for internal analytical purposes to improve our services, but this data will never identify you personally.
* **Control:** You retain full control over your data. You can review, update, or delete your profile information at any time through the app\'s settings.
* **Purpose-Driven:** Data is collected only to enhance your financial planning experience and provide relevant advice.

We are committed to transparent data practices. For more details, please refer to our full Privacy Policy [Link to Privacy Policy - Placeholder].
""";
}

// Custom Formatter for PAN Card (e.g., ABCDE1234F -> ABCDE 1234 F)
class PanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > 10) {
      return oldValue;
    }
    String text = newValue.text.toUpperCase();
    String newText = '';
    if (text.length > 5) {
      newText += text.substring(0, 5) + ' ';
      text = text.substring(5);
    } else {
      return newValue.copyWith(text: text);
    }
    if (text.length > 4) {
      newText += text.substring(0, 4) + ' ';
      text = text.substring(4);
    } else {
      return newValue.copyWith(text: newText + text);
    }
    newText += text;
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// Custom Formatter for Aadhaar Card (e.g., 123456789012 -> 1234 5678 9012)
class AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > 12) {
      return oldValue;
    }
    String text = newValue.text;
    String newText = '';
    if (text.length > 4) {
      newText += text.substring(0, 4) + ' ';
      text = text.substring(4);
    } else {
      return newValue.copyWith(text: text);
    }
    if (text.length > 4) {
      newText += text.substring(0, 4) + ' ';
      text = text.substring(4);
    } else {
      return newValue.copyWith(text: newText + text);
    }
    newText += text;
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
