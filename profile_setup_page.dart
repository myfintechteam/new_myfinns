import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:myfin/constants.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ArrowShapeBorder extends OutlinedBorder {
  const ArrowShapeBorder({super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) => ArrowShapeBorder(side: side.scale(t));

  @override
  ShapeBorder lerpFrom(ShapeBorder? a, double t) {
    if (a is ArrowShapeBorder) {
      return ArrowShapeBorder(side: BorderSide.lerp(a.side, side, t));
    }
    final ShapeBorder? result = super.lerpFrom(a, t);
    return result ?? this;
  }

  @override
  ShapeBorder lerpTo(ShapeBorder? b, double t) {
    if (b is ArrowShapeBorder) {
      return ArrowShapeBorder(side: BorderSide.lerp(side, b.side, t));
    }
    final ShapeBorder? result = super.lerpTo(b, t);
    return result ?? this;
  }

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return ArrowShapeBorder(side: side ?? this.side);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double tipWidth = rect.height / 2;
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right - tipWidth, rect.top)
      ..lineTo(rect.right, rect.top + rect.height / 2)
      ..lineTo(rect.right - tipWidth, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) {
      return;
    }
    final double tipWidth = rect.height / 2;
    final Path path = Path()
      ..moveTo(rect.left + side.width / 2, rect.top + side.width / 2)
      ..lineTo(rect.right - tipWidth, rect.top + side.width / 2)
      ..lineTo(rect.right - side.width / 2, rect.top + rect.height / 2)
      ..lineTo(rect.right - tipWidth, rect.bottom - side.width / 2)
      ..lineTo(rect.left + side.width / 2, rect.bottom - side.width / 2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = side.color
        ..strokeWidth = side.width
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool get preferPaintInterior => true;
}

class ProfileSetupPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentThemeMode;

  final Map<String, dynamic>? initialProfileData;

  const ProfileSetupPage({
    Key? key,
    required this.toggleTheme,
    required this.currentThemeMode,
    this.initialProfileData,
  }) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with AutomaticKeepAliveClientMixin {
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isFetchingProfile = true;
  String? _errorMessage;
  String? _fetchProfileError;

  final String _backendBaseUrl = AppConstants.backendBaseUrl;

  // --- Session 1: Personal Information ---
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'Prefer not to say';
  String? _occupation;
  final TextEditingController _otherOccupationController =
      TextEditingController();
  String? _educationalQualification;
  Uint8List? _photographIpvBytes;
  bool _addNominee = false;
  final TextEditingController _nomineeNameController = TextEditingController();
  final TextEditingController _nomineeMobileController =
      TextEditingController();
  final TextEditingController _nomineeEmailController = TextEditingController();

  // --- Session 2: KYC Verification ---
  final TextEditingController _panController = TextEditingController();
  bool _isPanVerified = false;
  bool _isVerifyingPan = false;
  String? _panVerificationError;
  bool _showPanDetails = false;
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isAadhaarVerified = false;
  String? _aadhaarReferenceId;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _aadhaarVerificationError;
  final TextEditingController _bankAccountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  bool _isBankVerified = false;
  bool _isVerifyingBank = false;
  String? _bankVerificationError;
  String? _addressProofType;
  final TextEditingController _addressProofDetailsController =
      TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _creditScoreController = TextEditingController();
  String? _annualSalaryRange;
  Uint8List? _incomeProofBytes;

  // --- Session 3: Terms & Conditions & Consent ---
  bool _agreedToTerms = false;
  bool _consentCallSmsEmail = false;
  bool _consentWhatsapp = false;
  bool _bypassSuitabilityAnalysis = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfileData != null) {
      _populateFields(widget.initialProfileData!);
      _isFetchingProfile = false;
    } else {
      _fetchUserProfile();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _otpController.dispose();
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
        _populateFields(data);
        setState(() {
          _isFetchingProfile = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _isFetchingProfile = false;
          _fetchProfileError = null;
          _emailIdController.text = user.email ?? '';
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

  void _populateFields(Map<String, dynamic> data) {
    setState(() {
      _firstNameController.text = data['first_name'] ?? '';
      _middleNameController.text = data['middle_name'] ?? '';
      _lastNameController.text = data['last_name'] ?? '';
      _dateOfBirth = data['date_of_birth'] != null
          ? DateTime.tryParse(data['date_of_birth'])
          : null;
      _gender = data['gender'] ?? 'Prefer not to say';
      _panController.text = data['pan_card'] ?? '';
      _isPanVerified = data['pan_card'] != null && data['pan_card'].isNotEmpty;
      _aadhaarController.text = data['aadhaar_card'] ?? '';
      _isAadhaarVerified =
          data['aadhaar_card'] != null && data['aadhaar_card'].isNotEmpty;
      _addressProofType = data['address_proof_type'];
      _addressProofDetailsController.text = data['address_proof_details'] ?? '';
      _photographIpvBytes = data['photograph_ipv'] != null
          ? base64Decode(data['photograph_ipv'])
          : null;

      _bankAccountNumberController.text = data['bank_account_number'] ?? '';
      _ifscCodeController.text = data['ifsc_code'] ?? '';
      _isBankVerified = data['bank_account_number'] != null &&
          data['bank_account_number'].isNotEmpty &&
          data['ifsc_code'] != null &&
          data['ifsc_code'].isNotEmpty;
      _annualSalaryRange = data['annual_salary_range'];
      _incomeProofBytes = data['income_proof'] != null
          ? base64Decode(data['income_proof'])
          : null;
      _creditScoreController.text = (data['credit_score'] ?? '').toString();

      _mobileNumberController.text = data['mobile_number'] ?? '';
      _emailIdController.text =
          data['email_id'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
      _occupation = data['occupation'];
      if (_occupation == 'Other') {
        _otherOccupationController.text = data['other_occupation'] ?? '';
      }
      _educationalQualification = data['educational_qualification'];
      _addNominee = data['add_nominee'] ?? false;
      _nomineeNameController.text = data['nominee_name'] ?? '';
      _nomineeMobileController.text = data['nominee_mobile'] ?? '';
      _nomineeEmailController.text = data['nominee_email'] ?? '';

      _agreedToTerms = data['agreed_to_terms'] ?? false;
      _consentCallSmsEmail = data['consent_call_sms_email'] ?? false;
      _consentWhatsapp = data['consent_whatsapp'] ?? false;
      _bypassSuitabilityAnalysis = data['bypass_suitability_analysis'] ?? false;
    });
  }

  Future<void> _verifyPan() async {
    if (!RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
    ).hasMatch(_panController.text.replaceAll(' ', ''))) {
      setState(() {
        _panVerificationError = 'Please enter a valid 10-digit PAN number.';
      });
      return;
    }

    setState(() {
      _isVerifyingPan = true;
      _panVerificationError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/kyc/verify-pan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pan': _panController.text.replaceAll(' ', ''),
          'name_as_per_pan':
              '${_firstNameController.text} ${_lastNameController.text}',
          'date_of_birth': _dateOfBirth != null
              ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
              : null,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final panStatus = responseData['data']['status'];

        if (panStatus == 'valid') {
          setState(() {
            _isPanVerified = true;
            _isVerifyingPan = false;
          });
          _showSnackBar('PAN successfully verified!', Colors.green);
        } else {
          setState(() {
            _panVerificationError =
                'PAN verification failed. The provided PAN is not valid.';
            _isVerifyingPan = false;
          });
          _showSnackBar(_panVerificationError!, Colors.red);
        }
      } else {
        setState(() {
          _panVerificationError =
              responseData['error'] ?? 'Failed to verify PAN.';
          _isVerifyingPan = false;
        });
        _showSnackBar(_panVerificationError!, Colors.red);
      }
    } catch (e) {
      setState(() {
        _panVerificationError = 'Network error: ${e.toString()}';
        _isVerifyingPan = false;
      });
      _showSnackBar(_panVerificationError!, Colors.red);
    }
  }

  Future<void> _verifyBankAccount() async {
    if (_bankAccountNumberController.text.isEmpty ||
        _ifscCodeController.text.isEmpty) {
      setState(() {
        _bankVerificationError =
            'Please enter both Bank Account Number and IFSC code.';
      });
      return;
    }

    setState(() {
      _isVerifyingBank = true;
      _bankVerificationError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$_backendBaseUrl/api/kyc/verify-bank-account/${_ifscCodeController.text.replaceAll(' ', '')}/${_bankAccountNumberController.text.replaceAll(' ', '')}',
        ),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseData['message'] == 'Bank account verified successfully.') {
        setState(() {
          _isBankVerified = true;
          _isVerifyingBank = false;
        });
        _showSnackBar('Bank account verified successfully!', Colors.green);
      } else {
        setState(() {
          _bankVerificationError =
              responseData['error'] ?? 'Bank account verification failed.';
          _isVerifyingBank = false;
        });
        _showSnackBar(_bankVerificationError!, Colors.red);
      }
    } catch (e) {
      setState(() {
        _bankVerificationError = 'Network error: ${e.toString()}';
        _isVerifyingBank = false;
      });
      _showSnackBar(_bankVerificationError!, Colors.red);
    }
  }

  Future<void> _generateAadhaarOtp() async {
    if (_aadhaarController.text.replaceAll(' ', '').length != 12) {
      setState(() {
        _aadhaarVerificationError =
            'Please enter a valid 12-digit Aadhaar number.';
      });
      return;
    }
    setState(() {
      _isSendingOtp = true;
      _aadhaarVerificationError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/kyc/generate-aadhaar-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'aadhaar_number': _aadhaarController.text.replaceAll(' ', ''),
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _aadhaarReferenceId = responseData['data']['reference_id'].toString();
          _isSendingOtp = false;
        });
        _showSnackBar(
          'OTP sent to your Aadhaar-linked mobile number.',
          Colors.green,
        );
      } else {
        setState(() {
          _aadhaarVerificationError =
              responseData['error'] ?? 'Failed to send OTP.';
          _isSendingOtp = false;
        });
        _showSnackBar(_aadhaarVerificationError!, Colors.red);
      }
    } catch (e) {
      setState(() {
        _aadhaarVerificationError = 'Network error: ${e.toString()}';
        _isSendingOtp = false;
      });
      _showSnackBar(_aadhaarVerificationError!, Colors.red);
    }
  }

  Future<void> _verifyAadhaarOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _aadhaarVerificationError = 'Please enter the OTP.';
      });
      return;
    }
    setState(() {
      _isVerifyingOtp = true;
      _aadhaarVerificationError = null;
    });

    if (_aadhaarReferenceId == null) {
      setState(() {
        _aadhaarVerificationError = 'Reference ID not found. Please resend OTP.';
        _isVerifyingOtp = false;
      });
      _showSnackBar(_aadhaarVerificationError!, Colors.red);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/kyc/verify-aadhaar-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reference_id': _aadhaarReferenceId,
          'otp': _otpController.text,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseData['status'] == 'Success') {
          setState(() {
            _isAadhaarVerified = true;
            _isVerifyingOtp = false;
          });
          _showSnackBar('Aadhaar successfully verified!', Colors.green);
        } else {
          setState(() {
            _aadhaarVerificationError =
                responseData['message'] ?? 'OTP verification failed.';
            _isVerifyingOtp = false;
          });
          _showSnackBar(_aadhaarVerificationError!, Colors.red);
        }
      } else {
        setState(() {
          _aadhaarVerificationError =
              responseData['error'] ?? 'Failed to verify OTP.';
          _isVerifyingOtp = false;
        });
        _showSnackBar(_aadhaarVerificationError!, Colors.red);
      }
    } catch (e) {
      setState(() {
        _aadhaarVerificationError = 'Network error: ${e.toString()}';
        _isVerifyingOtp = false;
      });
      _showSnackBar(_aadhaarVerificationError!, Colors.red);
    }
  }

  bool _isCurrentSessionValid() {
    switch (_currentPage) {
      case 0: // Personal Information
        // **RE-ENABLED AND FIXED VALIDATION LOGIC**
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _dateOfBirth != null &&
            _gender.isNotEmpty &&
            _occupation != null &&
            (_occupation != 'Other' ||
                _otherOccupationController.text.isNotEmpty) &&
            _educationalQualification != null &&
            _photographIpvBytes != null &&
            (!_addNominee ||
                (_nomineeNameController.text.isNotEmpty &&
                    _nomineeMobileController.text.replaceAll(' ', '').length ==
                        10 &&
                    _nomineeEmailController.text.isNotEmpty));
      case 1: // Verify with KYC
        // **RE-ENABLED AND FIXED VALIDATION LOGIC**
        return _isPanVerified &&
            _isAadhaarVerified &&
            _isBankVerified &&
            _mobileNumberController.text.replaceAll(' ', '').length == 10 &&
            _emailIdController.text.isNotEmpty &&
            _creditScoreController.text.isNotEmpty &&
            (int.tryParse(_creditScoreController.text) ?? 0) >= 300 &&
            (int.tryParse(_creditScoreController.text) ?? 0) <= 600 &&
            _addressProofType != null &&
            _addressProofDetailsController.text.isNotEmpty &&
            _annualSalaryRange != null &&
            _incomeProofBytes != null;
      case 2: // Device Permissions & Security
        return true;
      case 3: // Terms & Conditions
        return _agreedToTerms;
      default:
        return false;
    }
  }

  Future<void> _pickFile(Function(Uint8List?) onPicked) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickMedia();

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

    if (!_isCurrentSessionValid()) {
      _showSnackBar(
        'Please complete all mandatory fields in the current section.',
        Colors.orange,
      );
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

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firebase_uid': user.uid,
          'first_name': _firstNameController.text,
          'middle_name': _middleNameController.text.isEmpty
              ? null
              : _middleNameController.text,
          'last_name': _lastNameController.text,
          'date_of_birth': _dateOfBirth?.toIso8601String(),
          'gender': _gender,
          'occupation': _occupation,
          'other_occupation': _occupation == 'Other'
              ? _otherOccupationController.text
              : null,
          'educational_qualification': _educationalQualification,
          'photograph_ipv': _photographIpvBytes != null
              ? base64Encode(_photographIpvBytes!)
              : null,
          'add_nominee': _addNominee,
          'nominee_name': _addNominee ? _nomineeNameController.text : null,
          'nominee_mobile': _addNominee ? _nomineeMobileController.text : null,
          'nominee_email': _addNominee ? _nomineeEmailController.text : null,
          'pan_card': _panController.text.replaceAll(' ', ''),
          'aadhaar_card': _aadhaarController.text.replaceAll(' ', ''),
          'address_proof_type': _addressProofType,
          'address_proof_details': _addressProofDetailsController.text,
          'bank_account_number': _bankAccountNumberController.text,
          'ifsc_code': _ifscCodeController.text,
          'mobile_number': _mobileNumberController.text,
          'email_id': _emailIdController.text,
          'credit_score': int.tryParse(_creditScoreController.text),
          'annual_salary_range': _annualSalaryRange,
          'income_proof': _incomeProofBytes != null
              ? base64Encode(_incomeProofBytes!)
              : null,
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

  Widget _buildNavigationButton(
    BuildContext context, {
    required int pageIndex,
    required String title,
    required IconData icon,
  }) {
    final bool isSelected = _currentPage == pageIndex;
    final Color color = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return SizedBox(
      height: 70,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _currentPage = pageIndex;
          });
        },
        icon: Icon(icon, color: color),
        label: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
          ),
          shape: ArrowShapeBorder(
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ),
    );
  }

  Widget _buildCurrentPageContent(BuildContext context) {
    switch (_currentPage) {
      case 0:
        return _buildPage(
          context,
          title: 'Personal Information',
          subtitle: 'Tell us a bit about yourself.',
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
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        controller: _middleNameController,
                        label: 'Middle Name (Optional)',
                        hint: 'M',
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Doe',
                        isMandatory: true,
                        onChanged: (value) => setState(() {}),
                      ),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _middleNameController,
                        label: 'Middle Name (Optional)',
                        hint: 'M',
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Doe',
                        isMandatory: true,
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
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
              onChanged: (date) => setState(() => _dateOfBirth = date),
            ),
            const SizedBox(height: 18),
            _buildDropdownField(
              label: 'Gender',
              value: _gender,
              items: ['Male', 'Female', 'Prefer not to say'],
              onChanged: (value) => setState(() => _gender = value!),
              isMandatory: true,
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
                if (value != 'Other') _otherOccupationController.clear();
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
                  onChanged: (value) => setState(() {}),
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
              onChanged: (value) =>
                  setState(() => _educationalQualification = value!),
              isMandatory: true,
            ),
            const SizedBox(height: 18),
            _buildFileUploadField(
              context,
              label: 'Photograph (for IPV)',
              buttonText: _photographIpvBytes != null
                  ? 'Change Photo'
                  : 'Upload Photo',
              icon: Icons.camera_alt,
              isMandatory: true,
              onPicked: (bytes) => setState(() => _photographIpvBytes = bytes),
              currentFileBytes: _photographIpvBytes,
            ),
            // const SizedBox(height: 24),
            // Card(
            //   elevation: 1,
            //   color: Theme.of(context).cardColor,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: ExpansionTile(
            //     title: Text(
            //       'Nominee Details (Optional)',
            //       style: TextStyle(
            //         color: Theme.of(context).textTheme.bodyLarge?.color,
            //       ),
            //     ),
            //     leading: Icon(
            //       Icons.group_add,
            //       color: Theme.of(context).iconTheme.color,
            //     ),
            //     onExpansionChanged: (expanded) =>
            //         setState(() => _addNominee = expanded),
            //     initiallyExpanded: _addNominee,
            //     children: [
            //       Padding(
            //         padding: const EdgeInsets.all(16.0),
            //         child: Column(
            //           children: [
            //             _buildTextField(
            //               controller: _nomineeNameController,
            //               label: 'Nominee Full Name',
            //               hint: 'Jane Doe',
            //               icon: Icons.person_outline,
            //               onChanged: (value) => setState(() {}),
            //             ),
            //             const SizedBox(height: 18),
            //             _buildTextField(
            //               controller: _nomineeMobileController,
            //               label: 'Nominee Mobile Number',
            //               hint: 'e.g., 9876543210',
            //               icon: Icons.phone,
            //               keyboardType: TextInputType.phone,
            //               inputFormatters: [
            //                 FilteringTextInputFormatter.digitsOnly,
            //                 LengthLimitingTextInputFormatter(10),
            //               ],
            //               onChanged: (value) => setState(() {}),
            //             ),
            //             const SizedBox(height: 18),
            //             _buildTextField(
            //               controller: _nomineeEmailController,
            //               label: 'Nominee Email ID',
            //               hint: 'jane.doe@example.com',
            //               icon: Icons.email,
            //               keyboardType: TextInputType.emailAddress,
            //               onChanged: (value) => setState(() {}),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            
          ],
        );
      case 1:
        return _buildPage(
          context,
          title: 'Verify with KYC',
          subtitle: 'Securely verify your identity and bank details.',
          children: [
            _buildPanVerificationField(),
            const SizedBox(height: 24),
            _buildAadhaarVerificationField(),
            const SizedBox(height: 24),
            _buildBankVerificationField(),
            // const SizedBox(height: 24),
            // _buildDropdownField(
            //   label: 'Address Proof Type',
            //   value: _addressProofType,
            //   items: ['Passport', 'Voter ID', 'Driving License', 'Utility Bill (last 3 months)'],
            //   onChanged: (value) => setState(() => _addressProofType = value!),
            //   isMandatory: true,
            // ),
            // if (_addressProofType != null) ...[
            //   const SizedBox(height: 18),
            //   _buildAddressProofDetailsField(context),
            // ],
            const SizedBox(height: 18),
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
                if (value.length != 10) return 'Mobile Number must be 10 digits';
                return null;
              },
              onChanged: (value) => setState(() {}),
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
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                  return 'Enter a valid email';
                return null;
              },
              onChanged: (value) => setState(() {}),
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
              onChanged: (value) => setState(() => _annualSalaryRange = value!),
              isMandatory: true,
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
              onChanged: (value) => setState(() {}),
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
              onPicked: (bytes) => setState(() => _incomeProofBytes = bytes),
              currentFileBytes: _incomeProofBytes,
            ),
          ],
        );
      case 2:
        return _buildPage(
          context,
          title: 'Device Permissions & Security',
          subtitle: 'Your privacy and security are our top priority.',
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
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        );
      case 3:
        return _buildPage(
          context,
          title: 'Terms and Conditions',
          subtitle: 'Your privacy and security are our top priority.',
          children: [
            Text(
              _termsAndConditionsText,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            _buildConsentCheckbox(
              label: 'I\'m ready to receive Call, SMS, Email communications',
              value: _consentCallSmsEmail,
              onChanged: (newValue) =>
                  setState(() => _consentCallSmsEmail = newValue ?? false),
            ),
            _buildConsentCheckbox(
              label:
                  'I\'m ready to receive Voice over Internet Protocol including WhatsApp communications',
              value: _consentWhatsapp,
              onChanged: (newValue) =>
                  setState(() => _consentWhatsapp = newValue ?? false),
            ),
            const SizedBox(height: 20),
            _buildConsentCheckbox(
              label:
                  'By selecting this, you declare to consciously bypass the recommended suitability module and purchase the policy based on your independent assessment.',
              value: _bypassSuitabilityAnalysis,
              onChanged: (newValue) => setState(
                () => _bypassSuitabilityAnalysis = newValue ?? false,
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
                  child: Text(
                    'I agree to the terms and conditions regarding data privacy.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPage(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
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
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              : Row(
                  children: [
                    if (isLargeScreen)
                      Container(
                        width: 250,
                        color: Theme.of(context).cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavigationButton(
                              context,
                              pageIndex: 0,
                              title: 'Personal Info',
                              icon: Icons.person_outline,
                            ),
                            _buildNavigationButton(
                              context,
                              pageIndex: 1,
                              title: 'Verify with KYC',
                              icon: Icons.verified_user,
                            ),
                            _buildNavigationButton(
                              context,
                              pageIndex: 2,
                              title: 'Device Permissions & Security',
                              icon: Icons.security,
                            ),
                            _buildNavigationButton(
                              context,
                              pageIndex: 3,
                              title: 'Terms & Conditions',
                              icon: Icons.assignment_turned_in_outlined,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isLargeScreen ? 900 : double.infinity,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: _buildCurrentPageContent(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0 && !isLargeScreen)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentPage--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentPage > 0 && _currentPage < 3 && !isLargeScreen)
              const SizedBox(width: 16),
            if (_currentPage < 3 && !isLargeScreen)
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCurrentSessionValid()
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
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
              ),
            if (_currentPage == 3)
              Expanded(
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _agreedToTerms && _isCurrentSessionValid()
                            ? _saveProfileAndNavigate
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Agree & Finish Setup'),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanVerificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'PAN Card Number',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
                const SizedBox(width: 8),
                if (_isPanVerified)
                  Icon(Icons.verified, color: Colors.green, size: 20),
                if (_isPanVerified)
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _panController,
                label: '',
                hint: 'ABCDE1234F',
                icon: Icons.credit_card,
                isMandatory: true,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'PAN is mandatory';
                  if (!RegExp(
                    r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
                  ).hasMatch(value.replaceAll(' ', '')))
                    return 'Invalid PAN format';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isPanVerified = false;
                    _showPanDetails = value.length == 10;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            _isVerifyingPan
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed:
                        (_firstNameController.text.isNotEmpty &&
                                _lastNameController.text.isNotEmpty &&
                                _dateOfBirth != null)
                            ? _verifyPan
                            : null,
                    child: const Text('Verify PAN'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                    ),
                  ),
          ],
        ),
        if (_panVerificationError != null && !_isPanVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _panVerificationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        // if (_showPanDetails) ...[
        //   const SizedBox(height: 18),
        //   Text(
        //     'Please fill in your full name and date of birth as per your PAN card.',
        //     style: TextStyle(
        //       fontSize: 14,
        //       fontStyle: FontStyle.italic,
        //       color: Theme.of(context).textTheme.bodyMedium?.color,
        //     ),
        //   ),
        //   const SizedBox(height: 12),
        //   LayoutBuilder(
        //     builder: (context, constraints) {
        //       if (constraints.maxWidth < 450) {
        //         return Column(
        //           children: [
        //             _buildTextField(
        //               controller: _firstNameController,
        //               label: 'First Name',
        //               hint: 'John',
        //               isMandatory: true,
        //               onChanged: (value) => setState(() {}),
        //             ),
        //             const SizedBox(height: 18),
        //             _buildTextField(
        //               controller: _middleNameController,
        //               label: 'Middle Name (Optional)',
        //               hint: 'M',
        //               onChanged: (value) => setState(() {}),
        //             ),
        //             const SizedBox(height: 18),
        //             _buildTextField(
        //               controller: _lastNameController,
        //               label: 'Last Name',
        //               hint: 'Doe',
        //               isMandatory: true,
        //               onChanged: (value) => setState(() {}),
        //             ),
        //           ],
        //         );
        //       }
        //       return Row(
        //         children: [
        //           Expanded(
        //             child: _buildTextField(
        //               controller: _firstNameController,
        //               label: 'First Name',
        //               hint: 'John',
        //               isMandatory: true,
        //               onChanged: (value) => setState(() {}),
        //             ),
        //           ),
        //           const SizedBox(width: 12),
        //           Expanded(
        //             child: _buildTextField(
        //               controller: _middleNameController,
        //               label: 'Middle Name (Optional)',
        //               hint: 'M',
        //               onChanged: (value) => setState(() {}),
        //             ),
        //           ),
        //           const SizedBox(width: 12),
        //           Expanded(
        //             child: _buildTextField(
        //               controller: _lastNameController,
        //               label: 'Last Name',
        //               hint: 'Doe',
        //               isMandatory: true,
        //               onChanged: (value) => setState(() {}),
        //             ),
        //           ),
        //         ],
        //       );
        //     },
        //   ),
        //   const SizedBox(height: 18),
        //   _buildDatePickerField(
        //     context,
        //     label: 'Date of Birth',
        //     selectedDate: _dateOfBirth,
        //     isMandatory: true,
        //     onChanged: (date) => setState(() => _dateOfBirth = date),
        //   ),
        //   const SizedBox(height: 18),
        //   _isVerifyingPan
        //       ? const CircularProgressIndicator()
        //       : ElevatedButton(
        //           onPressed:
        //               (_firstNameController.text.isNotEmpty &&
        //                       _lastNameController.text.isNotEmpty &&
        //                       _dateOfBirth != null)
        //                   ? _verifyPan
        //                   : null,
        //           child: const Text('Verify PAN'),
        //         ),
        // ],
      ],
    );
  }

  Widget _buildAadhaarVerificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Aadhaar Card Number',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(' (*)', style: TextStyle(fontSize: 12, color: Colors.red)),
            const SizedBox(width: 8),
            if (_isAadhaarVerified)
              Icon(Icons.verified, color: Colors.green, size: 20),
            if (_isAadhaarVerified)
              Text(
                'Verified',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (!_isAadhaarVerified && _aadhaarReferenceId == null)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _aadhaarController,
                  label: '',
                  hint: 'Enter your 12-digit Aadhaar number',
                  icon: Icons.fingerprint,
                  isMandatory: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Aadhaar is mandatory';
                    if (value.replaceAll(' ', '').length != 12)
                      return 'Aadhaar number must be 12 digits';
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              _isSendingOtp
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _generateAadhaarOtp,
                      child: const Text('Send OTP'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 50),
                      ),
                    ),
            ],
          ),
        if (_aadhaarVerificationError != null && _aadhaarReferenceId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _aadhaarVerificationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (_aadhaarReferenceId != null && !_isAadhaarVerified)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _otpController,
                      label: 'OTP',
                      hint: 'Enter the 6-digit OTP',
                      icon: Icons.dialpad,
                      isMandatory: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'OTP is mandatory';
                        if (value.length != 6) return 'OTP must be 6 digits';
                        return null;
                      },
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isVerifyingOtp
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _verifyAadhaarOtp,
                          child: const Text('Verify OTP'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                          ),
                        ),
                ],
              ),
              if (_aadhaarVerificationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _aadhaarVerificationError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildBankVerificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _bankAccountNumberController,
          label: 'Bank Account Number',
          hint: 'e.g., 123456789012',
          icon: Icons.account_balance,
          isMandatory: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Account number is mandatory';
            if (value.length < 9 || value.length > 18)
              return 'Invalid account number length';
            return null;
          },
          onChanged: (value) {
            setState(() {
              _isBankVerified = false;
            });
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ifscCodeController,
                label: 'IFSC Code',
                hint: 'ABCD0123456',
                icon: Icons.code,
                isMandatory: true,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'IFSC Code is mandatory';
                  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value))
                    return 'Invalid IFSC format';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isBankVerified = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            _isVerifyingBank
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isBankVerified ? null : _verifyBankAccount,
                    child: const Text('Verify'),
                  ),
          ],
        ),
        if (_bankVerificationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _bankVerificationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (_isBankVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bank account verified!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddressProofDetailsField(BuildContext context) {
    String labelText = 'Address Proof Details';
    String hintText = 'Enter details for selected proof';
    TextInputType keyboardType = TextInputType.text;
    List<TextInputFormatter>? inputFormatters;
    String? Function(String?)? validator;

    switch (_addressProofType) {
      case 'Passport':
        labelText = 'Passport Number';
        hintText = 'e.g., M1234567';
        inputFormatters = [LengthLimitingTextInputFormatter(9)];
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
        inputFormatters = [LengthLimitingTextInputFormatter(10)];
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
        inputFormatters = [LengthLimitingTextInputFormatter(16)];
        validator = (value) {
          if (value == null || value.isEmpty)
            return 'Driving License Number is mandatory';
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
      onChanged: (value) => setState(() {}),
    );
  }

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
        if (label.isNotEmpty)
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
        if (label.isNotEmpty) const SizedBox(height: 4),
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
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

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
              ? (val) => val == null || val.isEmpty || val == 'Prefer not to say'
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
                ? DateFormat('d/M/yyyy').format(selectedDate)
                : '',
          ),
          decoration: InputDecoration(
            hintText: 'Select Date',
            prefixIcon: const Icon(Icons.calendar_today),
            border: InputBorder.none,
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
                                primary: Theme.of(context).primaryColor,
                                onPrimary: Colors.white,
                                surface: Theme.of(context).cardColor,
                                onSurface: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black,
                              )
                            : ColorScheme.dark(
                                primary: Theme.of(context).primaryColor,
                                onPrimary: Colors.white,
                                surface: Theme.of(context).cardColor,
                                onSurface: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.white,
                              ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
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
                onPressed: () => _pickFile(onPicked),
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
