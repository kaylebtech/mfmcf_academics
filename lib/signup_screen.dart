import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mfmcf_academics/home_screen.dart';
import 'package:mfmcf_academics/login_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

// Mock navigation screens (replace with your actual routes)
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("Terms & Conditions")));
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("Privacy Policy")));
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _acceptedTerms = false;

  // Device token
  String? _deviceToken;

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Dropdowns
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedLevel;

  final List<String> colleges = ['CHS', 'CSET', 'JUPEB'];
  Map<String, List<String>> departments = {
    'CHS': [
      'B. Health Information Management',
      'B. Environmental Health Science',
      'M.B.B.S.',
      'B.Sc. Nursing',
      'B.Sc. Physiology',
      'B.Sc. Public Health',
      'B.MLS',
      'B.Sc. Nutrition and Dietetics',
      'B.Sc. Radiography and Radiation Science',
      'B.Sc. Pharmacology',
      'B.Sc. Anatomy',
      'B.Sc. Biochemistry',
      'B.Sc. Biotechnology',
      'B.Sc. Microbiology',
    ],
    'CSET': [
      'B.Eng. Agric. Engineering',
      'B.Eng. Chemical Engineering',
      'B.Eng. Civil Engineering',
      'B.Eng. Electrical/Electronics',
      'B.Eng. Mechanical Engineering',
      'B.Sc. Computer Science',
      'B.Sc. Cybersecurity',
      'B.Sc. Information Science',
      'B.Sc. Software Engineering',
      'B.Sc. Information Technology',
      'B.Sc. Statistics',
      'B.Sc. Mathematics',
      'B.Sc. Physics with Electronics',
      'B.Sc. Chemistry',
      'B.Sc. Industrial Chemistry',
      'B.Sc. Geology',
      'B.Sc. Science Laboratory',
      'B.Sc. Plant Biology',
      'B.Sc. Animal and Environmental Biology',
      'Industrial Mathematics',
      'B.Sc. Building',
      'B.Sc. Estate Management',
      'B.Sc. Food Science & Tech.',
      'B.Sc. Quantity Survey',
      'B.Sc. Architecture',
      'B.Sc. Urban & Regional Planning',
    ],
    'JUPEB': ['Science', 'Arts', 'Social Sciences'],
  };
  final List<String> levels = ['100', '200', '300', '400', '500'];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  // Initialize Firebase Messaging and get device token
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for notifications
      final messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      // Get device token
      final token = await messaging.getToken();
      if (token != null) {
        setState(() {
          _deviceToken = token;
        });
        debugPrint('Device Token: $token');
      } else {
        debugPrint('Could not get device token');
      }

      // Handle token refresh
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('Device token refreshed: $newToken');
        setState(() {
          _deviceToken = newToken;
        });
      });
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _matricController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Show beautiful toast
  void _showToast(String message, {bool isError = true}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: isError
          ? Colors.red.withOpacity(0.9)
          : Colors.green.withOpacity(0.9),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _signUp() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      _showToast("Please fill all required fields correctly");
      return;
    }

    // Check if terms are accepted
    if (!_acceptedTerms) {
      _showToast("Please accept Terms & Privacy Policy");
      return;
    }

    // Validate dropdowns manually
    if (_selectedCollege == null) {
      _showToast("Please select your college");
      return;
    }
    if (_selectedDepartment == null) {
      _showToast("Please select your department");
      return;
    }
    if (_selectedLevel == null) {
      _showToast("Please select your level");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get trimmed values
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();
      final fullName = _fullNameController.text.trim();
      final phone = _phoneController.text.trim();
      final matricNumber = _matricController.text.trim();

      debugPrint("Starting signup process for email: $email");

      // 1. Create Firebase Auth user
      final authResult = await auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = authResult.user;
      if (user == null) {
        throw Exception("User creation failed - no user returned");
      }

      final uid = user.uid;
      debugPrint("User created successfully with UID: $uid");

      // 2. Store device information
      final deviceInfo = {
        'deviceToken': _deviceToken,
        'deviceType': Platform.isIOS
            ? 'iOS'
            : Platform.isAndroid
            ? 'Android'
            : 'Web',
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
        'appVersion': '1.0.0', // You should get this from your pubspec.yaml
        'lastActive': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // 3. Store user data in Firestore
      final userData = {
        'uid': uid,
        'username': username,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'matricNumber': matricNumber,
        'college': _selectedCollege,
        'department': _selectedDepartment,
        'level': _selectedLevel,
        'role': 'student',
        'accountStatus': 'active',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'profileImage': '',
        'notificationSettings': {
          'pushNotifications': true,
          'emailNotifications': true,
          'smsNotifications': false,
          'classReminders': true,
          'assignmentDeadlines': true,
          'examNotifications': true,
        },
        'devices': {_deviceToken ?? 'unknown': deviceInfo},
      };

      debugPrint("Attempting to save user data to Firestore...");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      debugPrint("User data saved to Firestore successfully");

      // 4. Also store device token in a separate collection for easier querying
      if (_deviceToken != null && _deviceToken!.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('user_devices')
              .doc(_deviceToken)
              .set({
                'userId': uid,
                'deviceToken': _deviceToken,
                'deviceInfo': deviceInfo,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                'isActive': true,
              });
          debugPrint("Device token saved to user_devices collection");
        } catch (e) {
          debugPrint("Error saving device token to separate collection: $e");
          // Continue even if this fails
        }
      }

      // 5. Subscribe to topics based on user's college, department, and level
      try {
        final messaging = FirebaseMessaging.instance;

        // Subscribe to general topic
        await messaging.subscribeToTopic('all_users');

        // Subscribe to college topic
        if (_selectedCollege != null) {
          final collegeTopic = _selectedCollege!.toLowerCase().replaceAll(
            ' ',
            '_',
          );
          await messaging.subscribeToTopic('college_$collegeTopic');
        }

        // Subscribe to department topic
        if (_selectedDepartment != null) {
          final deptTopic = _selectedDepartment!.toLowerCase().replaceAll(
            ' ',
            '_',
          );
          await messaging.subscribeToTopic('department_$deptTopic');
        }

        // Subscribe to level topic
        if (_selectedLevel != null) {
          await messaging.subscribeToTopic('level_$_selectedLevel');
        }

        debugPrint("Subscribed to notification topics");
      } catch (e) {
        debugPrint("Error subscribing to topics: $e");
        // Continue even if subscription fails
      }

      // 6. Send email verification (optional but recommended)
      try {
        await user.sendEmailVerification();
        debugPrint("Verification email sent");
      } catch (e) {
        debugPrint("Email verification send failed: $e");
        // Don't stop the signup process if email verification fails
      }

      // Show success message
      _showToast("Account created successfully!", isError: false);

      // 7. Navigate to Home after a short delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on auth.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
      String message = "Signup failed";

      switch (e.code) {
        case 'email-already-in-use':
          message = "This email is already registered. Please login instead.";
          break;
        case 'invalid-email':
          message = "Invalid email format. Please check and try again.";
          break;
        case 'weak-password':
          message = "Password is too weak. Use at least 6 characters.";
          break;
        case 'operation-not-allowed':
          message = "Email/password accounts are not enabled. Contact support.";
          break;
        case 'network-request-failed':
          message = "Network error. Please check your internet connection.";
          break;
        default:
          message = "Signup failed: ${e.message ?? 'Unknown error'}";
      }
      _showToast(message);
    } on FirebaseException catch (e) {
      debugPrint("FirebaseException: ${e.code} - ${e.message}");
      String message = "Database error occurred";

      if (e.code == 'permission-denied') {
        message = "Permission denied. Please check Firestore security rules.";
      } else if (e.code == 'unavailable') {
        message = "Service unavailable. Please try again later.";
      } else {
        message = "Database error: ${e.message ?? 'Unknown error'}";
      }
      _showToast(message);
    } catch (e) {
      debugPrint("Unexpected error during signup: $e");
      _showToast("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Cream
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.02,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.02),
                Text(
                  'Create Account',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE75480), // Pink shade
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join MFMCF UNIOSUN community',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 28),

                // Username
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Iconsax.user,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full Name
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Iconsax.profile_2user,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Full name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Iconsax.direct_right,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (v.trim().length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Matric Number
                _buildTextField(
                  controller: _matricController,
                  label: 'Matric Number',
                  icon: Iconsax.document_text_1,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Matric number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Iconsax.password_check,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // College Dropdown
                _buildDropdown(
                  label: 'College',
                  value: _selectedCollege,
                  items: colleges,
                  onChanged: (val) => setState(() {
                    _selectedCollege = val;
                    _selectedDepartment =
                        null; // Reset dept when college changes
                  }),
                ),

                const SizedBox(height: 16),

                // Department Dropdown
                _buildDropdown(
                  label: 'Department',
                  value: _selectedDepartment,
                  items: _selectedCollege != null
                      ? departments[_selectedCollege]!
                      : [],
                  enabled: _selectedCollege != null,
                  onChanged: (val) => setState(() => _selectedDepartment = val),
                ),

                const SizedBox(height: 16),

                // Level Dropdown
                _buildDropdown(
                  label: 'Level',
                  value: _selectedLevel,
                  items: levels,
                  onChanged: (val) => setState(() => _selectedLevel = val),
                ),

                const SizedBox(height: 24),

                // Notification Permission Text (Optional)
                if (_deviceToken == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Colors.amber[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enabling notifications for important updates...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Terms & Privacy
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      activeColor: const Color(0xFFE75480),
                      onChanged: (bool? value) =>
                          setState(() => _acceptedTerms = value ?? false),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: Color(0xFFE75480),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsPage(),
                                  ),
                                ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Color(0xFFE75480),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyPage(),
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE75480),
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.pink.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Already have account?
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log In',
                          style: const TextStyle(
                            color: Color(0xFFE75480),
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              if (!_isLoading) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE75480)),
        labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE75480), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    final isEnabled = enabled && !_isLoading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: false,
          isExpanded: true,
          hint: Text(
            'Select $label',
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: isEnabled ? onChanged : null,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isEnabled ? const Color(0xFFE75480) : Colors.grey,
          ),
          style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }
}
